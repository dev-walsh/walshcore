# Replit.md

## Overview

This is **Walsh Core Framework** - a fully custom FiveM/GTA V multiplayer modification designed for PvP gameplay with "100k or Die" survival mechanics. The framework serves as a demonstration of AI's capability in game development, with all functions and references branded as "Walsh Core." Players must maintain at least $100,000 to survive, manage gang territories in red zones, and engage in competitive PvP combat.

## User Preferences

Preferred communication style: Simple, everyday language.
Framework Name: Walsh Core (all functions and references must use "walsh")
Color Scheme: Purple (#8B5CF6) and White (#FFFFFF)
Logo: Walsh logo with stylized "W" design (walsh-logo.png)

## System Architecture

The project follows a **comprehensive FiveM framework architecture** with complete server-side and client-side implementation:

- **Server-Side**: Lua-based modular system handling player management, economy, gangs, jobs, red zones, vehicles, weapons, and admin tools
- **Client-Side**: Lua modules for UI integration, player interactions, and game mechanics
- **Database**: MySQL database with comprehensive schema for all framework data
- **Frontend**: HTML/CSS/JavaScript web interface that communicates with the game client via NUI
- **UI Framework**: Bootstrap 5.1.3 for responsive design components with Walsh Core branding
- **Communication**: Event-driven architecture using both server-client events and NUI callbacks

## Key Components

### 1. HUD System
- **Money Display**: Shows cash and bank amounts with wallet/bank icons
- **Player Status Bars**: Health, armor, and stamina progress bars
- **Needs Display**: Player survival needs tracking (partially implemented)

### 2. UI Elements
- **Notification System**: Queue-based notification display
- **Menu System**: Dynamic menu rendering for various game interactions
- **Modal Interfaces**: ATM, vehicle shop, and other interactive screens
- **Status Screens**: Death screen, elimination screen, low money warnings

### 3. Visual Design
- **Glassmorphism Theme**: Semi-transparent backgrounds with blur effects
- **Dark Color Scheme**: Black backgrounds with white text for gaming aesthetics
- **Responsive Layout**: Fixed positioning for HUD elements
- **Icon Integration**: Font Awesome icons for visual consistency

## Data Flow

1. **Game Client → UI**: Game sends data via `postMessage` API
2. **Event Processing**: JavaScript event handlers process different message types
3. **DOM Updates**: UI elements are updated dynamically based on game state
4. **User Interactions**: UI sends responses back to game client (implementation pending)

### Core Framework Features:
- **Economy System**: $100k survival requirement with automatic elimination system
- **Gang Management**: Territory control, warfare, member management, and ranking systems
- **Red Zone PvP**: Territorial control areas with rewards and contest mechanics
- **Job System**: Police, mechanic, and other employment with pay grades
- **Vehicle System**: Ownership, shops, fuel management, and garage systems
- **Weapon System**: Shops, licensing, durability, and combat mechanics
- **Admin Tools**: Comprehensive administrative commands and player management
- **Database Integration**: Complete MySQL schema with transaction logging and optimization

## External Dependencies

### CDN Resources:
- **Bootstrap 5.1.3**: UI framework for responsive components
- **Font Awesome 6.0.0**: Icon library for UI elements

### Integration Platform:
- **FiveM NUI**: Native User Interface system for GTA V modifications
- **WebView**: Chromium-based rendering engine within the game

## Deployment Strategy

The project is designed for **FiveM resource deployment**:

1. **Static Web Assets**: HTML, CSS, and JS files served through FiveM's resource system
2. **Client-Side Only**: No server-side components in current implementation
3. **Resource Structure**: Follows FiveM naming conventions for web assets in `html/` directory
4. **Integration**: Communicates with Lua scripts via NUI callbacks (Lua side not present in repository)

### Architecture Decisions:

**Problem**: Need for complete FiveM framework like QBCore
**Solution**: Modular resource architecture with walsh-core foundation and separate resource modules
**Rationale**: Allows for easy maintenance, updates, and customization while following FiveM best practices

**Problem**: Consistent Walsh branding throughout framework
**Solution**: All functions, events, and references use "walsh" prefix with purple/white color scheme
**Rationale**: Creates professional, cohesive brand identity across all framework components

**Problem**: Real-time UI updates with custom Walsh branding
**Solution**: NUI-based HUD system with purple/white glassmorphism design and Walsh logo integration
**Rationale**: Provides modern gaming interface while maintaining Walsh brand consistency