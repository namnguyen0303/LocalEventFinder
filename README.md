# Local Event Finder

Submitted by: Nam Nguyen - z23539620

Youtube Link for the presentation: https://www.youtube.com/watch?v=da_7NHdfZCQ

## **Table of Contents**
1. Overview
2. Product Spec
3. Wireframes
4. Schema

---

## **Overview**

### **Description**  
Local Event Finder is a mobile application that allows users to discover and explore events happening around their location. Users can sign up, log in, view event details, and personalize their experience with optional features like saving events, searching by filters, and receiving reminders for saved events.

### **App Evaluation**
- **Category**: Entertainment / Social  
- **Mobile**: Designed exclusively for mobile devices to ensure on-the-go access to event details.  
- **Story**: Helps users discover local events and plan their activities with ease.  
- **Market**: Targeted at anyone looking for local events, including young adults, families, and travelers.  
- **Habit**: Likely used occasionally, based on when users need event recommendations.  
- **Scope**: Focused on event discovery and details with potential to expand into event management features.  

---

## **Product Spec**

### **1. Completed User Stories**

#### **Required Must-have Stories (build sprint 1)**  
1. **User can register for an account.**  
2. **User can log in to their account.**  
3. **User can sign out.**  
4. **User can view a list of events based on their location.**  
5. **User can view detailed information about an event.**  
6. **User can edit their information such as name and date of birth.**  

#### **Optional Nice-to-have Stories (build sprint 2)**  
1. **User can save an event to their favorites and unsave it.**  
2. **User can search for events with different locations and different search radius.**  
3. **User can filter events based on its categories such as Music, Sports, or Arts & Theatre.**  
4. **User can search for an event's name using the search bar tool.**  
5. **User can receive reminders about upcoming events.**  
6. **User can see the event's location, and the app can also redirect them to Apple Maps/Google Maps.**  

---

### **2. Screen Archetypes**
- **Login Screen**  
  - User can log in.  
- **Registration Screen**  
  - User can create a new account.  
- **Profile Screen**  
  - User can edit their personal information.  
  - User can log out.  
- **Event List Screen**  
  - User can view a list of events.  
- **Event Detail Screen**  
  - User can view detailed information about an event.  

---

### **3. Navigation**  

#### **Tab Navigation**  
- Events List  
- Profile  

#### **Flow Navigation**  
- Login Screen → Events List Screen  
- Registration Screen → Events List Screen  
- Events List Screen  
  - → Event Detail Screen  
  - → Favorites Screen  
  - → Location Settings Screen  
- Profile Screen  
  - → Edit Profile Screen (after clicking "Edit Profile" option)  
  - → Login Screen (after clicking "Sign Out" option)  

---

## **Wireframes**  

![wireframe](https://github.com/user-attachments/assets/5a543867-114f-4c09-8c65-7bb1c5fc2dff)

## Video Walkthrough


![LocalEventFinder](https://github.com/user-attachments/assets/8a774bb9-b17b-4c12-be50-38730b20f920)


# GIF for Unit 8 - Build Sprint 1


![unit8](https://github.com/user-attachments/assets/e733c24c-e387-468f-b3a0-05cc4e9fa8b4)


# GIF for Unit 9 - Build Sprint 2


![unit9 1](https://github.com/user-attachments/assets/db0078ab-59ba-4c55-b8df-5bb7f8ca08c6)


---

#### **User Model**  

| Property    | Type   | Description                                    |
|-------------|--------|------------------------------------------------|
| email       | String | User's email address.                          |
| password    | String | Hashed password for authentication.            |
| name        | String | User's name.                                   |
| dateOfBirth | Date   | User's date of birth.                          |

#### **Event Model**  

| Property    | Type   | Description                                    |
|-------------|--------|------------------------------------------------|
| title       | String | Title of the event.                            |
| date        | Date   | Date and time of the event.                    |
| location    | String | Address or venue of the event.                 |
| description | String | Detailed description of the event.             |
| category    | String | Category of the event (e.g., Music, Sports).   |
| isFavorite  | Boolean| Indicates if the event is saved by the user.   |

---

## **Networking**

### **List of Network Requests by Screen**

#### **Login Screen**  
- **[POST] /firebase/auth/login**  
  - Authenticate user credentials using Firebase Authentication.

#### **Registration Screen**  
- **[POST] /firebase/auth/register**  
  - Create a new user account in Firebase Authentication.  

#### **Events List Screen**  
- **[GET] /discovery/v2/events**  
  - Fetch a list of events based on user location using the Ticketmaster API.  

#### **Event Detail Screen**  
- **[GET] /discovery/v2/events/{id}**  
  - Fetch detailed information for a specific event using the Ticketmaster API.  


#### **Favorites Screen**  
- **[POST] /firebase/firestore/events/{eventId}/favorite**  
  - Save an event to the user’s favorites in Firebase Firestore.  
- **[DELETE] /firebase/firestore/events/{eventId}/favorite**  
  - Remove an event from the user’s favorites in Firebase Firestore.  
- **[GET] /firebase/firestore/users/{userId}/favorites**  
  - Retrieve the list of favorite events saved by the user.
 

#### **Location Settings Screen**
- **[GET] /discovery/v2/events**  
  - Fetch a list of events based on the user-selected location and search radius.  

- **[GET] /geolocation/v1/cities**  
  - Fetch popular cities to display as location suggestions.
  

#### **Profile Screen**  
- **[GET] /firebase/firestore/users/{userId}**  
  - Retrieve user profile information from Firebase Firestore.  
- **[PUT] /firebase/firestore/users/{userId}**  
  - Update user profile information in Firebase Firestore.  
- **[POST] /firebase/auth/logout**  
  - Log out the user from Firebase Authentication.  



## License

    Copyright [2024] [Nam Nguyen]

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,


