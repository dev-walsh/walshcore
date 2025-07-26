// Global variables
let playerData = {};
let currentInterface = null;
let notificationQueue = [];
let currentMenu = null;
let gangInviteData = null;

// Initialize NUI
window.addEventListener('message', function(event) {
    const data = event.data;
    
    switch(data.type) {
        case 'updatePlayerData':
            updatePlayerData(data.data);
            break;
        case 'updateMoney':
            updateMoney(data.money, data.bank);
            break;
        case 'showNotification':
            showNotification(data.message, data.notificationType);
            break;
        case 'updateJob':
            updateJob(data.job, data.grade);
            break;
        case 'updateGang':
            updateGang(data.gang, data.grade);
            break;
        case 'showDeathScreen':
            toggleDeathScreen(data.show);
            break;
        case 'showElimination':
            toggleEliminationScreen(data.show);
            break;
        case 'showLowMoneyWarning':
            toggleLowMoneyWarning(data.show, data.amount, data.required);
            break;
        case 'showRedZoneWarning':
            toggleRedZoneWarning(data.show, data.zone);
            break;
        case 'showMenu':
            showMenu(data.menu);
            break;
        case 'hideUI':
            hideAllInterfaces();
            break;
        case 'showATM':
            showATM(data.show, data.playerData);
            break;
        case 'showVehicleShop':
            showVehicleShop(data.shop);
            break;
        case 'showWeaponShop':
            showWeaponShop(data.shop, data.weapons);
            break;
        case 'showGangMenu':
            showGangMenu(data.gang, data.playerData);
            break;
        case 'showGangInvitation':
            showGangInvitation(data.data);
            break;
        case 'showZoneContest':
            showZoneContest(data.data);
            break;
        case 'showZoneControlChange':
            showZoneControlChange(data.data);
            break;
        case 'showInteractionPrompt':
            showInteractionPrompt(data.show, data.text);
            break;
        case 'showRefuelProgress':
            showRefuelProgress(data.show, data.cost);
            break;
        case 'updateRefuelProgress':
            updateRefuelProgress(data.progress, data.fuel);
            break;
        case 'showWeaponWheel':
            showWeaponWheel(data.weapons);
            break;
        case 'showAnnouncement':
            showAnnouncement(data.message, data.sender);
            break;
        case 'addChatMessage':
            addChatMessage(data.data);
            break;
        case 'updateVehicleFuel':
            updateVehicleFuel(data.fuel);
            break;
        case 'updateStatus':
            updatePlayerStatus(data.status, data.value);
            break;
        case 'updateNeeds':
            updateNeeds(data.hunger, data.thirst);
            break;
        case 'updateStress':
            updateStress(data.stress);
            break;
        case 'updateCombatMode':
            updateCombatMode(data);
            break;
        default:
            console.log('Unknown message type:', data.type);
    }
});

// Player Data Management
function updatePlayerData(data) {
    playerData = data;
    updateMoney(data.money, data.bank);
    updateJob(data.job, data.job_grade);
    updateGang(data.gang, data.gang_grade);
}

function updateMoney(cash, bank) {
    document.getElementById('cash-amount').textContent = '$' + formatNumber(cash);
    document.getElementById('bank-amount').textContent = '$' + formatNumber(bank);
    
    // Update ATM display if open
    if (document.getElementById('atm-interface').style.display !== 'none') {
        document.getElementById('atm-cash').textContent = '$' + formatNumber(cash);
        document.getElementById('atm-bank').textContent = '$' + formatNumber(bank);
    }
}

function updateJob(job, grade) {
    playerData.job = job;
    playerData.job_grade = grade;
    // Update job display if needed
}

function updateGang(gang, grade) {
    playerData.gang = gang;
    playerData.gang_grade = grade;
    // Update gang display if needed
}

// Notification System
function showNotification(message, type = 'info') {
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
        <div class="notification-content">
            <i class="${iconMap[type]}"></i>
            <span>${message}</span>
        </div>
    `;
    
    container.appendChild(notification);
    
    // Auto remove after 5 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.style.animation = 'slideOutRight 0.3s ease';
            setTimeout(() => {
                container.removeChild(notification);
            }, 300);
        }
    }, 5000);
}

// Screen Overlays
function toggleDeathScreen(show) {
    const deathScreen = document.getElementById('death-screen');
    deathScreen.style.display = show ? 'block' : 'none';
    
    if (show) {
        startRespawnTimer();
    }
}

function toggleEliminationScreen(show) {
    const eliminationScreen = document.getElementById('elimination-screen');
    eliminationScreen.style.display = show ? 'block' : 'none';
}

function toggleLowMoneyWarning(show, amount, required) {
    const warning = document.getElementById('low-money-warning');
    warning.style.display = show ? 'block' : 'none';
    
    if (show) {
        document.getElementById('current-money').textContent = formatNumber(amount);
        document.getElementById('required-money').textContent = formatNumber(required);
    }
}

function toggleRedZoneWarning(show, zone) {
    const warning = document.getElementById('redzone-warning');
    warning.style.display = show ? 'block' : 'none';
    
    if (show && zone) {
        document.getElementById('redzone-name').textContent = zone.name;
    }
}

// Menu System
function showMenu(menu) {
    const menuContainer = document.getElementById('menu-container');
    const menuTitle = document.getElementById('menu-title');
    const menuItems = document.getElementById('menu-items');
    
    menuTitle.textContent = menu.title;
    menuItems.innerHTML = '';
    
    menu.items.forEach(item => {
        const menuItem = document.createElement('div');
        menuItem.className = 'menu-item';
        menuItem.innerHTML = `
            <span><i class="${item.icon || 'fas fa-circle'}"></i> ${item.label}</span>
            <i class="fas fa-chevron-right"></i>
        `;
        
        menuItem.addEventListener('click', () => {
            fetch(`https://${GetParentResourceName()}/menuAction`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ action: item.action, data: item })
            });
        });
        
        menuItems.appendChild(menuItem);
    });
    
    menuContainer.style.display = 'flex';
    currentInterface = 'menu';
}

// ATM Interface
function showATM(show, playerData) {
    const atmInterface = document.getElementById('atm-interface');
    atmInterface.style.display = show ? 'flex' : 'none';
    
    if (show && playerData) {
        document.getElementById('atm-cash').textContent = '$' + formatNumber(playerData.money);
        document.getElementById('atm-bank').textContent = '$' + formatNumber(playerData.bank);
        currentInterface = 'atm';
    }
}

function showDepositForm() {
    const form = document.getElementById('atm-form');
    const confirmBtn = document.getElementById('atm-confirm');
    
    form.style.display = 'block';
    document.getElementById('atm-amount').placeholder = 'Amount to deposit';
    
    confirmBtn.onclick = () => {
        const amount = parseInt(document.getElementById('atm-amount').value);
        if (amount > 0) {
            fetch(`https://${GetParentResourceName()}/depositMoney`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ amount })
            });
            hideATMForm();
        }
    };
}

function showWithdrawForm() {
    const form = document.getElementById('atm-form');
    const confirmBtn = document.getElementById('atm-confirm');
    
    form.style.display = 'block';
    document.getElementById('atm-amount').placeholder = 'Amount to withdraw';
    
    confirmBtn.onclick = () => {
        const amount = parseInt(document.getElementById('atm-amount').value);
        if (amount > 0) {
            fetch(`https://${GetParentResourceName()}/withdrawMoney`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ amount })
            });
            hideATMForm();
        }
    };
}

function hideATMForm() {
    document.getElementById('atm-form').style.display = 'none';
    document.getElementById('atm-amount').value = '';
}

function closeATM() {
    document.getElementById('atm-interface').style.display = 'none';
    currentInterface = null;
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Vehicle Shop
function showVehicleShop(shop) {
    const vehicleShop = document.getElementById('vehicle-shop');
    const vehicleGrid = document.getElementById('vehicle-grid');
    
    vehicleGrid.innerHTML = '';
    
    shop.vehicles.forEach(vehicle => {
        const vehicleCard = document.createElement('div');
        vehicleCard.className = 'vehicle-card';
        vehicleCard.innerHTML = `
            <div class="card-image">
                <i class="fas fa-car"></i>
            </div>
            <div class="card-title">${vehicle.model}</div>
            <div class="card-price">$${formatNumber(vehicle.price)}</div>
            <button class="btn btn-primary" onclick="purchaseVehicle('${vehicle.model}', ${vehicle.price}, '${shop.name}')">
                Purchase
            </button>
        `;
        
        vehicleGrid.appendChild(vehicleCard);
    });
    
    vehicleShop.style.display = 'flex';
    currentInterface = 'vehicle-shop';
}

function purchaseVehicle(model, price, shop) {
    fetch(`https://${GetParentResourceName()}/purchaseVehicle`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ model, price, shop })
    });
}

function closeVehicleShop() {
    document.getElementById('vehicle-shop').style.display = 'none';
    currentInterface = null;
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Weapon Shop
function showWeaponShop(shop, weapons) {
    const weaponShop = document.getElementById('weapon-shop');
    const weaponGrid = document.getElementById('weapon-grid');
    
    weaponGrid.innerHTML = '';
    
    weapons.forEach(weapon => {
        const weaponCard = document.createElement('div');
        weaponCard.className = 'weapon-card';
        weaponCard.innerHTML = `
            <div class="card-image">
                <i class="fas fa-gun"></i>
            </div>
            <div class="card-title">${getWeaponDisplayName(weapon.name)}</div>
            <div class="card-price">$${formatNumber(weapon.price)}</div>
            <div style="margin-top: 10px;">
                <button class="btn btn-primary" onclick="buyWeapon('${weapon.name}', ${weapon.price})">
                    Buy Weapon
                </button>
                <button class="btn btn-secondary" onclick="buyAmmo('${weapon.name}', ${weapon.ammoPrice})">
                    Buy Ammo ($${weapon.ammoPrice})
                </button>
            </div>
        `;
        
        weaponGrid.appendChild(weaponCard);
    });
    
    weaponShop.style.display = 'flex';
    currentInterface = 'weapon-shop';
}

function buyWeapon(weapon, price) {
    fetch(`https://${GetParentResourceName()}/buyWeapon`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ weapon, price })
    });
}

function buyAmmo(weapon, ammoPrice) {
    const amount = prompt('How much ammo do you want to buy?', '50');
    if (amount && parseInt(amount) > 0) {
        fetch(`https://${GetParentResourceName()}/buyAmmo`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ weapon, amount: parseInt(amount) })
        });
    }
}

function closeWeaponShop() {
    document.getElementById('weapon-shop').style.display = 'none';
    currentInterface = null;
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Gang System
function showGangMenu(gang, playerData) {
    const gangMenu = document.getElementById('gang-menu');
    const gangDetails = document.getElementById('gang-details');
    const gangActions = document.getElementById('gang-action-buttons');
    const gangMembers = document.getElementById('gang-member-list');
    
    if (gang) {
        gangDetails.innerHTML = `
            <div class="gang-stat">
                <span>Name:</span> <span>${gang.label}</span>
            </div>
            <div class="gang-stat">
                <span>Members:</span> <span>${gang.members.length}</span>
            </div>
            <div class="gang-stat">
                <span>Money:</span> <span>$${formatNumber(gang.money)}</span>
            </div>
            <div class="gang-stat">
                <span>Your Rank:</span> <span>${getRankName(playerData.gang_grade)}</span>
            </div>
        `;
        
        gangActions.innerHTML = `
            <button class="btn btn-primary" onclick="inviteToGang()">Invite Player</button>
            <button class="btn btn-warning" onclick="depositGangMoney()">Deposit Money</button>
            <button class="btn btn-danger" onclick="leaveGang()">Leave Gang</button>
        `;
        
        gangMembers.innerHTML = '';
        gang.members.forEach(member => {
            const memberItem = document.createElement('div');
            memberItem.className = 'member-item';
            memberItem.innerHTML = `
                <span>${member.name}</span>
                <span class="member-rank">${getRankName(member.rank)}</span>
            `;
            gangMembers.appendChild(memberItem);
        });
    } else {
        gangDetails.innerHTML = '<p>You are not in a gang</p>';
        gangActions.innerHTML = `
            <button class="btn btn-success" onclick="showCreateGangForm()">Create Gang</button>
        `;
        gangMembers.innerHTML = '';
    }
    
    gangMenu.style.display = 'flex';
    currentInterface = 'gang-menu';
}

function showGangInvitation(data) {
    gangInviteData = data;
    const invitation = document.getElementById('gang-invitation');
    
    document.getElementById('gang-invite-name').textContent = data.gangLabel;
    document.getElementById('gang-inviter').textContent = data.inviterName;
    
    invitation.style.display = 'flex';
}

function acceptGangInvitation() {
    if (gangInviteData) {
        fetch(`https://${GetParentResourceName()}/acceptGangInvitation`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                gangName: gangInviteData.gangName,
                inviterId: gangInviteData.inviterId
            })
        });
        
        document.getElementById('gang-invitation').style.display = 'none';
        gangInviteData = null;
    }
}

function declineGangInvitation() {
    document.getElementById('gang-invitation').style.display = 'none';
    gangInviteData = null;
}

function closeGangMenu() {
    document.getElementById('gang-menu').style.display = 'none';
    currentInterface = null;
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
}

// Zone Contest Display
function showZoneContest(data) {
    const contest = document.getElementById('zone-contest');
    const contestGangs = document.getElementById('contest-gangs');
    
    document.getElementById('contest-zone').textContent = data.zoneName;
    
    contestGangs.innerHTML = '';
    data.contestingGangs.forEach(gang => {
        const gangTag = document.createElement('div');
        gangTag.className = 'contest-gang';
        gangTag.textContent = gang;
        contestGangs.appendChild(gangTag);
    });
    
    contest.style.display = 'block';
    
    // Auto hide after 10 seconds
    setTimeout(() => {
        contest.style.display = 'none';
    }, 10000);
}

function showZoneControlChange(data) {
    showNotification(`${data.newController} has taken control of ${data.zoneName}!`, 'warning');
}

// Interaction Prompt
function showInteractionPrompt(show, text) {
    const prompt = document.getElementById('interaction-prompt');
    prompt.style.display = show ? 'block' : 'none';
    
    if (show && text) {
        document.getElementById('prompt-text').textContent = text;
    }
}

// Refuel Progress
function showRefuelProgress(show, cost) {
    const progress = document.getElementById('refuel-progress');
    progress.style.display = show ? 'block' : 'none';
    
    if (show && cost) {
        document.getElementById('refuel-cost').textContent = cost;
    }
}

function updateRefuelProgress(progress, fuel) {
    document.getElementById('refuel-progress-bar').style.width = progress + '%';
    document.getElementById('refuel-fuel').textContent = Math.round(fuel);
}

// Weapon Wheel
function showWeaponWheel(weapons) {
    const weaponWheel = document.getElementById('weapon-wheel');
    const weaponItems = document.getElementById('weapon-wheel-items');
    
    weaponItems.innerHTML = '';
    
    const radius = 150;
    const centerX = 200;
    const centerY = 200;
    
    weapons.forEach((weapon, index) => {
        const angle = (index * 360 / weapons.length) * Math.PI / 180;
        const x = centerX + radius * Math.cos(angle) - 30;
        const y = centerY + radius * Math.sin(angle) - 30;
        
        const weaponItem = document.createElement('div');
        weaponItem.className = 'weapon-wheel-item';
        weaponItem.style.left = x + 'px';
        weaponItem.style.top = y + 'px';
        weaponItem.innerHTML = `<i class="fas fa-gun"></i>`;
        weaponItem.title = weapon.displayName;
        
        weaponItem.addEventListener('click', () => {
            selectWeapon(weapon.name);
            hideWeaponWheel();
        });
        
        weaponItems.appendChild(weaponItem);
    });
    
    weaponWheel.style.display = 'flex';
}

function selectWeapon(weapon) {
    fetch(`https://${GetParentResourceName()}/selectWeapon`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ weapon })
    });
}

function hideWeaponWheel() {
    document.getElementById('weapon-wheel').style.display = 'none';
}

// Announcement System
function showAnnouncement(message, sender) {
    const announcement = document.getElementById('announcement');
    
    document.getElementById('announcement-text').textContent = message;
    document.getElementById('announcement-sender').textContent = sender;
    
    announcement.style.display = 'block';
    
    // Auto hide after 8 seconds
    setTimeout(() => {
        announcement.style.display = 'none';
    }, 8000);
}

// Chat System
function addChatMessage(data) {
    const chatMessages = document.getElementById('chat-messages');
    const message = document.createElement('div');
    
    if (data.template) {
        message.innerHTML = data.template.replace('{0}', data.args[0]).replace('{1}', data.args[1]);
    } else {
        message.className = 'chat-message';
        message.textContent = data.message || data;
    }
    
    chatMessages.appendChild(message);
    chatMessages.scrollTop = chatMessages.scrollHeight;
    
    // Remove old messages
    while (chatMessages.children.length > 50) {
        chatMessages.removeChild(chatMessages.firstChild);
    }
    
    // Auto hide messages after 10 seconds
    setTimeout(() => {
        if (message.parentNode) {
            message.style.opacity = '0.3';
        }
    }, 10000);
}

// Vehicle Status Updates
function updateVehicleFuel(fuel) {
    const fuelFill = document.getElementById('fuel-fill');
    const speedometer = document.getElementById('speedometer');
    
    if (fuel !== undefined) {
        fuelFill.style.width = fuel + '%';
        speedometer.style.display = 'block';
    } else {
        speedometer.style.display = 'none';
    }
}

// Player Status Updates
function updatePlayerStatus(status, value) {
    switch(status) {
        case 'health':
            document.getElementById('health-bar').style.width = value + '%';
            break;
        case 'armor':
            document.getElementById('armor-bar').style.width = value + '%';
            break;
        case 'stamina':
            document.getElementById('stamina-bar').style.width = value + '%';
            break;
    }
}

function updateNeeds(hunger, thirst) {
    document.getElementById('hunger-bar').style.width = hunger + '%';
    document.getElementById('thirst-bar').style.width = thirst + '%';
}

function updateStress(stress) {
    // Update stress indicators if needed
    if (stress > 80) {
        document.body.style.filter = 'blur(1px)';
    } else {
        document.body.style.filter = 'none';
    }
}

function updateCombatMode(data) {
    const body = document.body;
    
    if (data.inCombat) {
        body.classList.add('in-combat');
    } else {
        body.classList.remove('in-combat');
    }
    
    if (data.aiming) {
        body.classList.add('aiming');
    } else {
        body.classList.remove('aiming');
    }
}

// Utility Functions
function formatNumber(num) {
    return num.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

function getWeaponDisplayName(weaponName) {
    const displayNames = {
        'WEAPON_PISTOL': 'Pistol',
        'WEAPON_SMG': 'SMG',
        'WEAPON_ASSAULTRIFLE': 'Assault Rifle',
        'WEAPON_SNIPERRIFLE': 'Sniper Rifle',
        'WEAPON_SHOTGUN': 'Shotgun'
    };
    
    return displayNames[weaponName] || weaponName;
}

function getRankName(rank) {
    const ranks = ['Member', 'Lieutenant', 'Boss'];
    return ranks[rank] || 'Unknown';
}

function hideAllInterfaces() {
    const interfaces = [
        'menu-container',
        'atm-interface', 
        'vehicle-shop',
        'weapon-shop',
        'gang-menu',
        'gang-invitation',
        'weapon-wheel'
    ];
    
    interfaces.forEach(id => {
        document.getElementById(id).style.display = 'none';
    });
    
    currentInterface = null;
}

function startRespawnTimer() {
    let timer = 30;
    const timerElement = document.getElementById('respawn-timer');
    
    const countdown = setInterval(() => {
        timer--;
        timerElement.textContent = timer;
        
        if (timer <= 0) {
            clearInterval(countdown);
        }
    }, 1000);
}

// Event Listeners
document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && currentInterface) {
        hideAllInterfaces();
        fetch(`https://${GetParentResourceName()}/closeUI`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({})
        });
    }
});

// Close buttons
document.getElementById('menu-close').addEventListener('click', () => {
    hideAllInterfaces();
    fetch(`https://${GetParentResourceName()}/closeUI`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

// Weapon wheel mouse leave
document.getElementById('weapon-wheel').addEventListener('mouseleave', hideWeaponWheel);

// Context menu
document.addEventListener('contextmenu', function(event) {
    event.preventDefault();
    // Handle right-click context menu if needed
});

// Initialize on load
document.addEventListener('DOMContentLoaded', function() {
    console.log('Walsh Core Framework UI loaded');
    
    // Set initial values
    updateMoney(0, 0);
    updatePlayerStatus('health', 100);
    updatePlayerStatus('armor', 0);
    updatePlayerStatus('stamina', 100);
    updateNeeds(100, 100);
});
