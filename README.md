# Waypoint

**Branches:**  
- kaylas_branch: login page and launch page extras  
- lauras_branch: Adds persistant label to node with double tap -> just a text box  
- lauras_branch3: Adds persistant label to node with double tap that should take into account x and y coordinates (dependent on where screen is tapped)  
- niles_branch: path planning algorithm
- cates_branch: merged

**Testing**
- **Unit tests are found in waypoint_app/ARKitPersistenceTests.** Admin View Controller and User View Controller were tested to see if the correct number of UI elements appeared with the correct actions connected to them. Tests for Login View Controller have been started but are commented out, because it is currently more of a placeholder.
    - AdminViewControllerTests.swift
        - testIfUILabelExists
        - testIfLogoutButtonExists
        - testIfLoadButtonHasActionAssigned
        - testIfResetButtonHasActionAssigned
        - testIfSaveButtonHasActionAssigned
    - UserViewControllerTests.swift
        - testIfUILabelsExist
        - testIfLogoutButtonExists
        - testIfLoadButtonHasActionAssigned
        - testIfSearchButtonHasActionAssigned
    - ~~LoginViewControllerTests.swift~~
        - testIfLoginButtondExist
        - testAdminLoginButton_WhenTapped_AdminViewControllerIsPushed
        - testUserLoginButton_WhenTapped_UserViewControllerIsPushed

- It is difficult/costly to test an actual ARKit session, since it is hard to set up the entire environment that needs to be tested. Instead, we used debug print statements to test if the correct SCNNodes and ARAnchors appeared and persisted in an ARSession. 
