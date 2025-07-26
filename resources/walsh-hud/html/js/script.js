// Walsh Core HUD JavaScript
let WalshHUD = {
    playerData: {},
    notifications: [],
    vehicleData: {},
    inVehicle: false,
    isDead: false,
    respawnTimer: 30,
    survivalCheck: {
        active: false,
        timeLeft: 0
    }
};

// Initialize HUD
window.addEventListener('DOMContentLoaded', function() {
    console.log('Walsh Core HUD Loaded');
    
    // Hide HUD initially
    document.getElementById('hud-container').style.display = 'block';
    
    // Setup event listeners
    setupEventListeners();
    
    // Start update loops
    startUpdateLoops();
});

// Setup event listeners
function setupEventListeners() {
    // Respawn button
    document.getElementById('respawn-button').addEventListener('click', function() {
        if (!this.disabled) {
            fetch(`https://${GetParentResourceName()}/respawn`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }
    });

    // Walsh logo click
    document.getElementById('walsh-logo').addEventListener('click', function() {
        fetch(`https://${GetParentResourceName()}/openMenu`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ menu: 'main' })
        });
    });
}

// Start update loops
function startUpdateLoops() {
    // Update display every 100ms
    setInterval(updateDisplay, 100);
    
    // Clean up notifications every 5 seconds
    setInterval(cleanupNotifications, 5000);
}

// Message handler
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.action) {
        case 'updateHUD':
            updateHUD(data.data);
            break;
        case 'updateMoney':
            updateMoney(data.cash, data.bank);
            break;
        case 'updateHealth':
            updateHealth(data.health);
            break;
        case 'updateArmor':
            updateArmor(data.armor);
            break;
        case 'updateHunger':
            updateHunger(data.hunger);
            break;
        case 'updateThirst':
            updateThirst(data.thirst);
            break;
        case 'updateVehicle':
            updateVehicle(data.data);
            break;
        case 'showVehicleHUD':
            showVehicleHUD(data.show);
            break;
        case 'showNotification':
            showNotification(data.message, data.type, data.duration);
            break;
        case 'showDeathScreen':
            showDeathScreen(data.show);
            break;
        case 'showLowMoneyWarning':
            showLowMoneyWarning(data.show, data.current, data.required);
            break;
        case 'hideHUD':
            hideHUD(data.hide);
            break;
        case 'setCinematicMode':
            setCinematicMode(data.enabled);
            break;
        default:
            console.log('Unknown HUD action:', data.action);
    }
});

// Update HUD with player data
function updateHUD(data) {
    WalshHUD.playerData = data;
    
    if (data.money) {
        updateMoney(data.money.cash || 0, data.money.bank || 0);
    }
    
    if (data.metadata) {
        updateHealth(data.metadata.health || 100);
        updateArmor(data.metadata.armor || 0);
        updateHunger(data.metadata.hunger || 100);
        updateThirst(data.metadata.thirst || 100);
    }
}

// Update money display
function updateMoney(cash, bank) {
    document.getElementById('cash-amount').textContent = formatMoney(cash);
    document.getElementById('bank-amount').textContent = formatMoney(bank);
    
    // Check survival requirement
    const total = cash + bank;
    if (total < 100000 && !WalshHUD.isDead) {
        if (!WalshHUD.survivalCheck.active) {
            showLowMoneyWarning(true, total, 100000);
        }
    } else {
        showLowMoneyWarning(false);
    }
}

// Update health
function updateHealth(health) {
    const percentage = Math.max(0, Math.min(100, health));
    document.getElementById('health-value').textContent = Math.round(percentage) + '%';
    document.getElementById('health-progress').style.width = percentage + '%';
    
    // Change color based on health
    const progressBar = document.getElementById('health-progress');
    if (percentage < 25) {
        progressBar.style.background = 'linear-gradient(90deg, #EF4444, #DC2626)';
    } else if (percentage < 50) {
        progressBar.style.background = 'linear-gradient(90deg, #F59E0B, #D97706)';
    } else {
        progressBar.style.background = 'linear-gradient(90deg, var(--walsh-primary), var(--walsh-accent))';
    }
}

// Update armor
function updateArmor(armor) {
    const percentage = Math.max(0, Math.min(100, armor));
    document.getElementById('armor-value').textContent = Math.round(percentage) + '%';
    document.getElementById('armor-progress').style.width = percentage + '%';
}

// Update hunger
function updateHunger(hunger) {
    const percentage = Math.max(0, Math.min(100, hunger));
    document.getElementById('hunger-value').textContent = Math.round(percentage) + '%';
    document.getElementById('hunger-progress').style.width = percentage + '%';
    
    // Change color based on hunger
    const progressBar = document.getElementById('hunger-progress');
    if (percentage < 25) {
        progressBar.style.background = 'linear-gradient(90deg, #EF4444, #DC2626)';
    } else {
        progressBar.style.background = 'linear-gradient(90deg, var(--walsh-primary), var(--walsh-accent))';
    }
}

// Update thirst
function updateThirst(thirst) {
    const percentage = Math.max(0, Math.min(100, thirst));
    document.getElementById('thirst-value').textContent = Math.round(percentage) + '%';
    document.getElementById('thirst-progress').style.width = percentage + '%';
    
    // Change color based on thirst
    const progressBar = document.getElementById('thirst-progress');
    if (percentage < 25) {
        progressBar.style.background = 'linear-gradient(90deg, #EF4444, #DC2626)';
    } else {
        progressBar.style.background = 'linear-gradient(90deg, var(--walsh-primary), var(--walsh-accent))';
    }
}

// Update vehicle data
function updateVehicle(data) {
    WalshHUD.vehicleData = data;
    
    if (data.speed !== undefined) {
        document.getElementById('vehicle-speed').textContent = Math.round(data.speed) + ' MPH';
    }
    
    if (data.fuel !== undefined) {
        const fuelPercentage = Math.max(0, Math.min(100, data.fuel));
        document.getElementById('vehicle-fuel').textContent = Math.round(fuelPercentage) + '%';
        document.getElementById('fuel-progress').style.width = fuelPercentage + '%';
        
        // Change color based on fuel
        const fuelBar = document.getElementById('fuel-progress');
        if (fuelPercentage < 25) {
            fuelBar.style.background = 'linear-gradient(90deg, #EF4444, #DC2626)';
        } else {
            fuelBar.style.background = 'linear-gradient(90deg, var(--walsh-primary), var(--walsh-accent))';
        }
    }
    
    if (data.engine !== undefined) {
        const enginePercentage = Math.max(0, Math.min(100, data.engine));
        document.getElementById('vehicle-engine').textContent = Math.round(enginePercentage) + '%';
        document.getElementById('engine-progress').style.width = enginePercentage + '%';
        
        // Change color based on engine health
        const engineBar = document.getElementById('engine-progress');
        if (enginePercentage < 25) {
            engineBar.style.background = 'linear-gradient(90deg, #EF4444, #DC2626)';
        } else {
            engineBar.style.background = 'linear-gradient(90deg, var(--walsh-primary), var(--walsh-accent))';
        }
    }
}

// Show/hide vehicle HUD
function showVehicleHUD(show) {
    const vehicleHUD = document.getElementById('vehicle-hud');
    if (show) {
        vehicleHUD.classList.add('show');
        WalshHUD.inVehicle = true;
    } else {
        vehicleHUD.classList.remove('show');
        WalshHUD.inVehicle = false;
    }
}

// Show notification
function showNotification(message, type = 'info', duration = 5000) {
    const container = document.getElementById('notification-container');
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    
    const iconMap = {
        success: 'fas fa-check-circle',
        error: 'fas fa-exclamation-circle',
        warning: 'fas fa-exclamation-triangle',
        info: 'fas fa-info-circle'
    };
    
    notification.innerHTML = `
        <div class="notification-icon">
            <i class="${iconMap[type] || iconMap.info}"></i>
        </div>
        <div class="notification-content">
            <div class="notification-message">${message}</div>
        </div>
    `;
    
    // Add timestamp for cleanup
    notification.dataset.timestamp = Date.now();
    notification.dataset.duration = duration;
    
    container.appendChild(notification);
    WalshHUD.notifications.push(notification);
    
    // Auto remove after duration
    setTimeout(() => {
        removeNotification(notification);
    }, duration);
}

// Remove notification
function removeNotification(notification) {
    if (notification && notification.parentNode) {
        notification.style.animation = 'slideInRight 0.3s ease reverse';
        setTimeout(() => {
            if (notification.parentNode) {
                notification.parentNode.removeChild(notification);
            }
            const index = WalshHUD.notifications.indexOf(notification);
            if (index > -1) {
                WalshHUD.notifications.splice(index, 1);
            }
        }, 300);
    }
}

// Cleanup old notifications
function cleanupNotifications() {
    const now = Date.now();
    WalshHUD.notifications.forEach(notification => {
        const timestamp = parseInt(notification.dataset.timestamp);
        const duration = parseInt(notification.dataset.duration);
        if (now - timestamp > duration + 1000) {
            removeNotification(notification);
        }
    });
}

// Show death screen
function showDeathScreen(show) {
    const deathScreen = document.getElementById('death-screen');
    WalshHUD.isDead = show;
    
    if (show) {
        deathScreen.classList.add('show');
        startRespawnTimer();
    } else {
        deathScreen.classList.remove('show');
        WalshHUD.respawnTimer = 30;
    }
}

// Start respawn timer
function startRespawnTimer() {
    WalshHUD.respawnTimer = 30;
    const timerElement = document.getElementById('respawn-timer');
    const buttonElement = document.getElementById('respawn-button');
    
    const timer = setInterval(() => {
        if (WalshHUD.respawnTimer > 0) {
            timerElement.textContent = `Respawning in ${WalshHUD.respawnTimer} seconds...`;
            WalshHUD.respawnTimer--;
        } else {
            timerElement.textContent = 'You can now respawn';
            buttonElement.disabled = false;
            buttonElement.textContent = 'Respawn Now';
            clearInterval(timer);
        }
    }, 1000);
}

// Show low money warning
function showLowMoneyWarning(show, current = 0, required = 100000) {
    const warningElement = document.getElementById('low-money-warning');
    WalshHUD.survivalCheck.active = show;
    
    if (show) {
        document.getElementById('current-money').textContent = formatMoney(current);
        document.getElementById('required-money').textContent = formatMoney(required);
        warningElement.classList.add('show');
    } else {
        warningElement.classList.remove('show');
    }
}

// Hide/show HUD
function hideHUD(hide) {
    const hudContainer = document.getElementById('hud-container');
    if (hide) {
        hudContainer.classList.add('hidden');
    } else {
        hudContainer.classList.remove('hidden');
    }
}

// Set cinematic mode
function setCinematicMode(enabled) {
    const hudContainer = document.getElementById('hud-container');
    if (enabled) {
        hudContainer.classList.add('cinematic');
    } else {
        hudContainer.classList.remove('cinematic');
    }
}

// Update display
function updateDisplay() {
    // Update any real-time elements here
    if (WalshHUD.inVehicle && WalshHUD.vehicleData.speed !== undefined) {
        // Vehicle speed updates are handled in updateVehicle
    }
}

// Utility functions
function formatMoney(amount) {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD',
        minimumFractionDigits: 0,
        maximumFractionDigits: 0
    }).format(amount);
}

function GetParentResourceName() {
    return window.invokeNative ? window.invokeNative('getCurrentResourceName') : 'walsh-hud';
}

// Debug function
function debugHUD() {
    console.log('Walsh HUD Debug:', {
        playerData: WalshHUD.playerData,
        vehicleData: WalshHUD.vehicleData,
        inVehicle: WalshHUD.inVehicle,
        isDead: WalshHUD.isDead,
        notifications: WalshHUD.notifications.length
    });
}

// Make debug available globally
window.debugHUD = debugHUD;