// Define CameraManager as an object to encapsulate all related methods.
const CameraManager = {
    // Toggle visibility and clear content of the camera monitor.
    toggleCameraMonitor: function (show) {
        const $monitor = $('#camera-monitor');
        if (show) {
            $monitor.show();
        } else {
            $monitor.hide().empty();
        }
    },

    // Add a camera card to the UI.
    addCamera: function (camera) {
        const $cameraCard = $('<div>', {
            'class': 'camera-card',
            click: () => {
                console.log('Clicked camera:', camera.id);
                Events.Call("CameraClicked", camera.id);
            },
            css: { 'background-image': `url(${camera.img})` }
        });

        const $cameraName = $('<div>', {
            'class': 'camera-name',
            text: camera.name
        });

        const $cameraInfo = $('<div>', {
            'class': 'camera-info',
            html: `Rotation: ${camera.rotation}<br>Location: ${camera.location}`
        });

        $cameraCard.append($cameraName, $cameraInfo);
        $('#camera-monitor').append($cameraCard);
    },

    // Set up hotkeys in the UI.
    setHotkeys: function (hotkeys) {
        const $hotkeysContainer = $('.hotkeys').empty();
        hotkeys.forEach(hotkey => {
            let key = this.formatHotkeyIcon(hotkey.key);
            $hotkeysContainer.append(`
                <div class="hotkey">
                    <div class="key">${key}</div>
                    <p class="action">${hotkey.actionName}</p>
                </div>
            `);
        });
    },

    // Helper function to format hotkey icons.
    formatHotkeyIcon: function (key) {
        switch (key) {
            case "LeftClick": return '<img src="path/to/leftclick.svg" alt="Left Click">';
            case "RightMouseButton": return '<img src="path/to/rightclick.svg" alt="Right Click">';
            case "MouseScrollUp": return '<img src="path/to/scrollup.svg" alt="Scroll Up">';
            case "LeftShift": return 'Shift';
            default: return key;
        }
    },

    // Show notifications.
    showNotification: function (type, title, description) {
        console.log(type, title, description);
        const $notification = $(`
            <div class="notification entering ${type}">
                <div class="icon"><img src="./media/notif_${type}.svg" alt=""></div>
                <div class="content">
                    <h1 class="title">${title}</h1>
                    ${description ? `<p class="description">${description}</p>` : ""}
                </div>
                <svg class="close" width="20" height="20" viewBox="0 0 20 20" fill="none"
                    xmlns="http://www.w3.org/2000/svg">
                    <path d="M15 5L5 15M5 5L15 15" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
                </svg>
            </div>
        `);

        $('.notifications').append($notification);
        this.animateNotification($notification);
    },

    // Animate and remove notifications.
    animateNotification: function ($notification) {
        setTimeout(() => { $notification.removeClass('entering').addClass('entered'); }, 100);
        setTimeout(() => { $notification.removeClass('entered').addClass('leaving'); }, 5000);
        setTimeout(() => { $notification.remove(); }, 5500);

        $notification.find('.close').on('click', () => {
            $notification.removeClass('entered').addClass('leaving');
            setTimeout(() => { $notification.remove(); }, 500);
        });
    }
};

// Subscribing to events
Events.Subscribe("AddCamera", camera => CameraManager.addCamera(camera));
Events.Subscribe("ToggleCameraMonitor", show => CameraManager.toggleCameraMonitor(show));
Events.Subscribe("SetHotkeys", hotkeys => CameraManager.setHotkeys(hotkeys));
Events.Subscribe("ShowNotification", (type, title, description) => CameraManager.showNotification(type, title, description));
