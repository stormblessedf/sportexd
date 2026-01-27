# Sporsal - Implementation Plan

## 1. Project Overview
**Sporsal** is a social sports meetup application for Android and iOS. Users can organize sports events, join them, and socialize through automatically created chat groups. The app features a strong gamification system with badges and achievements to encourage participation and hosting.

## 2. Core Features Breakdown

### A. User Profile & Social Identity
- **Profile Info:** Name, Bio (Sports interests), Photos.
- **Certificates:** Special section to upload/display sports certificates (e.g., "Certified Yoga Instructor").
- **Social:** Follow/Unfollow system.
- **Direct Messaging:** 1-on-1 chat for followers.

### B. Meetup (Event) Management
- **Create Meetup:**
  - Date & Time
  - Location (Address/Map)
  - Activity Type (Football, Yoga, Running, etc.)
  - Participant Limit (Quota)
- **Join System:** Users join until quota is full.
- **Status:** Open, Full, Completed, Cancelled.

### C. Chat System
- **Event Chat:** Automatically created group chat for confirmed participants of a meetup.
- **Direct Chat:** Messaging between following users.

### D. Gamification (Badges & Achievements)
- **Participant Badges:** "First Game", "Reliable Player", "Weekender".
- **Organizer Badges:** "Community Leader", "Event Master".
- **Visuals:** High-quality icons/medals on the profile.

## 3. Data Structure (Firestore Schema)

### `users` (Collection)
- `uid`: string
- `displayName`: string
- `photoUrl`: string
- `bio`: string
- `certificates`: Array<{ title, imageUrl, date }>
- `badges`: Array<badgeId>
- `followers`: Array<uid>
- `following`: Array<uid>

### `meetups` (Collection)
- `id`: string
- `organizerId`: string
- `title`: string
- `location`: GeoPoint / string
- `date`: Timestamp
- `maxParticipants`: number
- `participants`: Array<uid>
- `chatGroupId`: string (linked to chat collection)
- `status`: 'open' | 'full' | 'completed'

### `chats` (Collection)
- `id`: string
- `meetupId`: string (optional, if event chat)
- `participants`: Array<uid>
- `messages`: Subcollection

## 4. Development Roadmap

- **Phase 1: Foundation & Identity (Current Focus)**
  - [x] Project Setup
  - [ ] Data Models
  - [ ] Profile Screen (UI + Dummy Data)
  - [ ] Certificate & Badge UI

- **Phase 2: Event System**
  - [ ] Create Meetup Form
  - [ ] Home Feed (Event Cards)
  - [ ] Join Logic

- **Phase 3: Social & Chat**
  - [ ] Follow System
  - [ ] Chat Screen UI

- **Phase 4: Polish**
  - [ ] Dark Mode refinements
  - [ ] Animations
