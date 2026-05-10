// ============================================================
// TEARC-Scanner NUI 音频引擎 + 菜单系统
// - 动态菜单渲染 (从Lua接收菜单数据)
// - 音频播放 (自动检测结束)
// - 音量归一化 (RMS响度均衡)
// - 3D音效 (基于距离的音量衰减, Lua端计算)
// ============================================================

const RESOURCE_NAME = window.GetParentResourceName ? window.GetParentResourceName() : 'tearc-scanner';

// NUI回调发送工具
function nuiCallback(name, data) {
    return fetch(`https://cfx-nui-${RESOURCE_NAME}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data || {}),
    }).catch(err => {
        console.error(`[TEARC-Scanner] NUI回调失败: ${name}`, err);
    });
}

// ============================================================
// 音频引擎
// ============================================================

const AudioEngine = {
    audioContext: null,
    masterGain: null,
    compressor: null,
    activeSources: {},
    sourceIdCounter: 0,
    masterVolume: 1.0,

    init() {
        if (this.audioContext) return;
        try {
            this.audioContext = new (window.AudioContext || window.webkitAudioContext)();

            this.compressor = this.audioContext.createDynamicsCompressor();
            this.compressor.threshold.value = -24;
            this.compressor.knee.value = 30;
            this.compressor.ratio.value = 12;
            this.compressor.attack.value = 0.003;
            this.compressor.release.value = 0.25;

            this.masterGain = this.audioContext.createGain();
            this.masterGain.gain.value = 1.0;

            this.compressor.connect(this.masterGain);
            this.masterGain.connect(this.audioContext.destination);

            console.log('[TEARC-Scanner] Web Audio 引擎初始化完成');
        } catch (e) {
            console.error('[TEARC-Scanner] AudioContext 初始化失败:', e);
        }
    },

    resume() {
        if (this.audioContext && this.audioContext.state === 'suspended') {
            this.audioContext.resume();
        }
    },

    calculateNormalizationGain(audioBuffer) {
        const channelData = audioBuffer.getChannelData(0);
        let sumSquares = 0;

        for (let i = 0; i < channelData.length; i++) {
            sumSquares += channelData[i] * channelData[i];
        }

        const rms = Math.sqrt(sumSquares / channelData.length);
        if (rms === 0) return 1.0;

        const targetRMS = 0.15;
        let gain = targetRMS / rms;
        gain = Math.max(0.3, Math.min(2.5, gain));

        return gain;
    },

    getAudioUrl(category, file) {
        const pathMap = {
            'scanner': 'scanner',
            'alerts': 'alerts',
            'backup_transport': 'backup/transport',
            'backup_coroner': 'backup/coroner',
            'backup_animal': 'backup/animal',
            'backup_supervisor': 'backup/supervisor',
        };
        const path = pathMap[category] || category;
        return `../audio/${path}/${file}`;
    },

    async playAudio(data) {
        this.resume();
        if (!this.audioContext) this.init();
        if (!this.audioContext) return;

        const { id, category, file, volume, loop, is3D } = data;
        const audioUrl = this.getAudioUrl(category, file);
        const sourceId = id || (++this.sourceIdCounter);

        try {
            const response = await fetch(audioUrl);
            if (!response.ok) {
                console.error(`[TEARC-Scanner] 音频加载失败: ${audioUrl} (HTTP ${response.status})`);
                return;
            }

            const arrayBuffer = await response.arrayBuffer();
            const audioBuffer = await this.audioContext.decodeAudioData(arrayBuffer);

            const normGain = this.calculateNormalizationGain(audioBuffer);
            const baseVolume = (volume !== undefined) ? volume : 1.0;
            const finalVolume = Math.max(0, Math.min(1, baseVolume * normGain * this.masterVolume));

            const source = this.audioContext.createBufferSource();
            source.buffer = audioBuffer;
            source.loop = !!loop;

            const gainNode = this.audioContext.createGain();
            gainNode.gain.value = finalVolume;

            source.connect(gainNode);
            gainNode.connect(this.compressor);

            source.onended = () => {
                if (this.activeSources[sourceId]) {
                    delete this.activeSources[sourceId];
                }
                nuiCallback('audioEnded', { category: category, file: file });
            };

            this.activeSources[sourceId] = { source, gainNode, category: category };
            source.start(0);

        } catch (e) {
            console.error(`[TEARC-Scanner] 播放失败: ${category}/${file}`, e);
        }
    },

    stopSound(id) {
        if (this.activeSources[id]) {
            try { this.activeSources[id].source.stop(); } catch (e) {}
            delete this.activeSources[id];
        }
    },

    stopCategory(category) {
        for (const id in this.activeSources) {
            if (this.activeSources[id].category === category) {
                try { this.activeSources[id].source.stop(); } catch (e) {}
                delete this.activeSources[id];
            }
        }
    },

    stopAll() {
        for (const id in this.activeSources) {
            try { this.activeSources[id].source.stop(); } catch (e) {}
            delete this.activeSources[id];
        }
    },

    updateSoundVolume(id, volume) {
        if (this.activeSources[id] && this.activeSources[id].gainNode) {
            const finalVolume = Math.max(0, Math.min(1, volume * this.masterVolume));
            this.activeSources[id].gainNode.gain.value = finalVolume;
        }
    },

    setMasterVolume(vol) {
        this.masterVolume = Math.max(0, Math.min(1, vol));
        if (this.masterGain) {
            this.masterGain.gain.value = this.masterVolume;
        }
    },
};

// ============================================================
// 菜单UI - 动态渲染 (从Lua接收数据)
// ============================================================

const MenuUI = {
    visible: false,
    selectedIndex: -1,
    currentItems: [],

    show(data) {
        this.visible = true;
        const container = document.getElementById('menu-container');
        container.classList.remove('menu-hidden');
        container.classList.add('menu-visible');

        if (data) {
            this.renderMenu(data);
        }
    },

    hide() {
        this.visible = false;
        const container = document.getElementById('menu-container');
        container.classList.remove('menu-visible');
        container.classList.add('menu-hidden');
        this.currentItems = [];
        this.selectedIndex = -1;
    },

    renderMenu(data) {
        const titleEl = document.getElementById('menu-title');
        const subtitleEl = document.getElementById('menu-subtitle');
        const itemsEl = document.getElementById('menu-items');

        if (data.title && titleEl) titleEl.textContent = data.title;
        if (data.subtitle && subtitleEl) subtitleEl.textContent = data.subtitle;

        if (!data.items || !itemsEl) return;

        itemsEl.innerHTML = '';
        this.currentItems = data.items;
        this.selectedIndex = -1;

        data.items.forEach((item, index) => {
            const itemEl = document.createElement('div');
            itemEl.className = 'menu-item';
            itemEl.dataset.index = index;

            const leftEl = document.createElement('div');
            leftEl.className = 'menu-item-left';

            const labelEl = document.createElement('div');
            labelEl.className = 'menu-item-label';
            labelEl.textContent = item.label;

            const descEl = document.createElement('div');
            descEl.className = 'menu-item-desc';
            descEl.textContent = item.description || '';

            leftEl.appendChild(labelEl);
            leftEl.appendChild(descEl);

            const rightEl = document.createElement('div');
            rightEl.className = 'menu-item-right';

            if (item.type === 'toggle') {
                const toggleEl = document.createElement('div');
                toggleEl.className = 'menu-toggle' + (item.state ? ' active' : '');

                const knobEl = document.createElement('div');
                knobEl.className = 'menu-toggle-knob';
                toggleEl.appendChild(knobEl);

                rightEl.appendChild(toggleEl);

                itemEl.addEventListener('click', () => {
                    nuiCallback('menuAction', {
                        id: item.id,
                        actionType: 'toggle',
                    }).then(resp => {
                        if (resp && resp.ok) return resp.json();
                    }).then(result => {
                        if (result && result.items) {
                            this.renderMenu({ items: result.items });
                        }
                    }).catch(() {});
                });

            } else if (item.type === 'slider') {
                const sliderWrap = document.createElement('div');
                sliderWrap.className = 'menu-slider';

                const sliderInput = document.createElement('input');
                sliderInput.type = 'range';
                sliderInput.min = item.min || 0;
                sliderInput.max = item.max || 100;
                sliderInput.step = item.step || 1;
                sliderInput.value = item.value || 50;

                const sliderValue = document.createElement('span');
                sliderValue.className = 'menu-slider-value';
                sliderValue.textContent = (item.value || 50) + '%';

                sliderInput.addEventListener('input', (e) => {
                    sliderValue.textContent = e.target.value + '%';
                });

                sliderInput.addEventListener('change', (e) => {
                    nuiCallback('menuAction', {
                        id: item.id,
                        actionType: 'slider',
                        value: parseInt(e.target.value),
                    }).then(resp => {
                        if (resp && resp.ok) return resp.json();
                    }).then(result => {
                        if (result && result.items) {
                            this.renderMenu({ items: result.items });
                        }
                    }).catch(() {});
                });

                sliderWrap.appendChild(sliderInput);
                sliderWrap.appendChild(sliderValue);
                rightEl.appendChild(sliderWrap);

            } else if (item.type === 'button') {
                const btnEl = document.createElement('div');
                btnEl.className = 'menu-button';
                btnEl.textContent = '执行';

                rightEl.appendChild(btnEl);

                itemEl.addEventListener('click', () => {
                    nuiCallback('menuAction', {
                        id: item.id,
                        actionType: 'button',
                    }).then(resp => {
                        if (resp && resp.ok) return resp.json();
                    }).then(result => {
                        if (result && result.items) {
                            this.renderMenu({ items: result.items });
                        }
                    }).catch(() {});
                });
            }

            itemEl.appendChild(leftEl);
            itemEl.appendChild(rightEl);
            itemsEl.appendChild(itemEl);
        });
    },
};

// ============================================================
// NUI消息处理
// ============================================================

window.addEventListener('message', function(event) {
    const { action, data } = event.data;

    switch (action) {
        case 'openMenu':
            MenuUI.show(data);
            break;

        case 'closeMenu':
            MenuUI.hide();
            break;

        case 'playAudio':
            AudioEngine.playAudio(data);
            break;

        case 'stopAudio':
            AudioEngine.stopSound(data.id);
            break;

        case 'stopCategory':
            AudioEngine.stopCategory(data.category);
            break;

        case 'stopAll':
            AudioEngine.stopAll();
            break;

        case 'updateVolume':
            if (data.id) {
                AudioEngine.updateSoundVolume(data.id, data.volume);
            }
            break;

        case 'setVolume':
            AudioEngine.setMasterVolume(data.volume);
            break;
    }
});

// ============================================================
// 键盘事件 (ESC关闭菜单)
// ============================================================

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape' && MenuUI.visible) {
        MenuUI.hide();
        nuiCallback('closeMenu');
    }
});

// ============================================================
// 初始化
// ============================================================

document.addEventListener('DOMContentLoaded', function() {
    const closeBtn = document.getElementById('close-btn');
    if (closeBtn) {
        closeBtn.addEventListener('click', function() {
            MenuUI.hide();
            nuiCallback('closeMenu');
        });
    }

    document.addEventListener('click', function() {
        AudioEngine.init();
        AudioEngine.resume();
    }, { once: true });

    console.log('[TEARC-Scanner] NUI 初始化完成');
});
