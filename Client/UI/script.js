const CameraManager = {
    adminPermission: false,
    screen: $(".screen"),

    toggleCameraMonitor: function (show) {
        const $monitor = $('#camera-monitor');
        if (show) {
            $monitor.show();
            $monitor.css('display', 'grid')
        } else {
            $monitor.hide().empty();
        }
    },

    addCamera: function (camera) {
        const $cameraCard = $('<div>', {
            'class': 'camera-card',
            css: { 'background-image': `url(${camera.img})` }
        }).appendTo('#camera-monitor');

        const $cameraName = $('<div>', {
            'class': 'camera-name',
            text: camera.name
        });

        const $cameraInfo = $('<div>', {
            'class': 'camera-info',
            html: `Rotation: ${camera.rotation}<br>Location: ${camera.location}`
        });

        const $confirmationOverlay = $('<div>', {
            'class': 'confirmation-overlay',
            html: `
                <p>Delete Camera ${camera.id}?</p>
                <button class="button confirm">Confirm</button>
                <button class="button cancel">Cancel</button>
            `,
            css: { display: 'none' }
        }).appendTo($cameraCard);

        $cameraCard.append($cameraName, $cameraInfo);

        $cameraCard.on('contextmenu', (event) => {
            if (!this.adminPermission) return;
            event.preventDefault();
            $confirmationOverlay.show();
            $cameraCard.css('background-image', 'url(path/to/black_screen.jpg)');
        });

        $confirmationOverlay.find('.confirm').on('click', (event) => {
            if (!this.adminPermission) return;
            event.stopPropagation();
            $cameraCard.remove();
            Events.Call("CameraRemoved", camera.id);
        });

        $confirmationOverlay.find('.cancel').on('click', (event) => {
            if (!this.adminPermission) return;
            event.stopPropagation();
            $confirmationOverlay.hide();
            $cameraCard.css('background-image', `url(${camera.img})`);
        });

        $cameraCard.on('click', (event) => {
            event.stopPropagation();
            Events.Call("CameraClicked", camera.id);
        });
    },

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

    formatHotkeyIcon: function (key) {
        switch (key) {
            case "LeftClick": return '<img src="path/to/leftclick.svg" alt="Left Click">';
            case "RightMouseButton": return '<img src="path/to/rightclick.svg" alt="Right Click">';
            case "MouseScrollUp": return `
                <svg width="24" height="26" viewBox="0 0 24 26" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M3.73096 10.7003C3.73096 8.06044 4.29473 5.75343 5.42228 3.77929C6.54983 1.80516 7.97585 0.630028 9.70034 0.253906V10.7003H3.73096Z" fill="#2DFF9B" fill-opacity="0.2"/>
                    <path d="M11.9389 25.6234C9.65238 25.6234 7.71257 24.8829 6.11946 23.4018C4.52634 21.9207 3.73018 20.1176 3.73096 17.9926V12.9385H20.1468V17.9926C20.1468 20.1184 19.3502 21.9218 17.7571 23.4029C16.164 24.884 14.2246 25.6242 11.9389 25.6234Z" fill="#2DFF9B" fill-opacity="0.2"/>
                    <rect x="11.1926" y="2.49219" width="1.49235" height="6.71556" rx="0.746173" fill="#57FFAF"/>
                    <path d="M14.1772 10.7003V0.253906C15.9017 0.631034 17.3278 1.80616 18.4553 3.77929C19.5829 5.75242 20.1466 8.05944 20.1466 10.7003H14.1772Z" fill="#2DFF9B" fill-opacity="0.2"/>
                </svg>`;
            case "LeftShift": return 'Shift';
            default: return key;
        }
    },

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


Events.Subscribe("CopyCoords", function (coords) {
    if (coords) {
        var tempTextArea = document.createElement("textarea");
        tempTextArea.value = coords;
        document.body.appendChild(tempTextArea);
        tempTextArea.select();
        try {
            document.execCommand("copy");
            CameraManager.showNotification("success", "Coordinates copied to clipboard", coords);
        } catch (err) {
            console.error('Failed to copy text: ', err);
        }
        document.body.removeChild(tempTextArea);
    }
});

Events.Subscribe("AddCamera", (camera) => {
    try {
        CameraManager.addCamera(camera);
    } catch (err) {
        console.error("Error adding camera:", err);
    }
});
Events.Subscribe("ToggleCameraMonitor", (show) => {
    try {
        CameraManager.toggleCameraMonitor(show);
    } catch (err) {
        console.error("Error toggling camera monitor:", err);
    }
});
Events.Subscribe("SetHotkeys", (hotkeys) => {
    try {
        CameraManager.setHotkeys(hotkeys);
    } catch (err) {
        console.error("Error setting hotkeys:", err);
    }
});
Events.Subscribe("ShowNotification", (type, title, description) => {
    try {
        CameraManager.showNotification(type, title, description);
    } catch (err) {
        console.error("Error showing notification:", err);
    }
});
Events.Subscribe("AdminPermission", (permission) => {
    try {
        CameraManager.adminPermission = permission;
    } catch (err) {
        console.error("Error setting admin permission:", err);
    }
});
