#!/usr/bin/env python3
"""Generate app_fr.arb and app_en.arb from a curated string catalog."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "lib" / "l10n"

# key -> (fr, en)
CATALOG = {
    "appTitle": ("uniSaps", "uniSaps"),
    "languageSelectionTitle": ("Choisis ta langue", "Choose your language"),
    "languageSelectionSubtitle": (
        "Tu pourras la modifier plus tard dans ton compte.",
        "You can change it later in your account settings.",
    ),
    "languageFrench": ("Français", "Français"),
    "languageEnglish": ("English", "English"),
    "languageContinue": ("Continuer", "Continue"),
    "settingsLanguage": ("Langue", "Language"),
    "settingsLanguageFrench": ("Français", "Français"),
    "settingsLanguageEnglish": ("English", "English"),
    "settingsDarkMode": ("Mode sombre", "Dark mode"),
    "commonCancel": ("Annuler", "Cancel"),
    "commonConfirm": ("Confirmer", "Confirm"),
    "commonValidate": ("Valider", "Validate"),
    "commonSave": ("Enregistrer", "Save"),
    "commonDelete": ("Supprimer", "Delete"),
    "commonRetry": ("Réessayer", "Retry"),
    "commonLater": ("Plus tard", "Later"),
    "commonNext": ("Suivant", "Next"),
    "commonPrevious": ("Précédent", "Previous"),
    "commonSkip": ("Passer", "Skip"),
    "tutorialGotIt": ("Compris !", "Got it!"),
    "commonAdd": ("Ajouter", "Add"),
    "commonClose": ("Fermer", "Close"),
    "commonBack": ("Retour", "Back"),
    "commonError": ("Erreur", "Error"),
    "commonLoading": ("Chargement…", "Loading…"),
    "commonYes": ("Oui", "Yes"),
    "commonNo": ("Non", "No"),
    "commonOk": ("OK", "OK"),
    "commonSearch": ("Rechercher", "Search"),
    "commonPublish": ("Publier", "Publish"),
    "commonEdit": ("Modifier", "Edit"),
    "commonShare": ("Partager", "Share"),
    "commonAll": ("Tout", "All"),
    "asyncErrorTitle": ("Impossible de charger", "Unable to load"),
    "asyncErrorSubtitle": (
        "Vérifie ta connexion et réessaie.",
        "Check your connection and try again.",
    ),
    "startupErrorTitle": ("Erreur au démarrage", "Startup error"),
    # Nav
    "navDressing": ("Dressing", "Wardrobe"),
    "navOutfits": ("Outfits", "Outfits"),
    "navInspiration": ("Inspiration", "Inspiration"),
    "navProfile": ("Profil", "Profile"),
    # Auth
    "authLoginTitle": ("Connexion", "Sign in"),
    "authLoginEmail": ("Email", "Email"),
    "authLoginPassword": ("Mot de passe", "Password"),
    "authLoginButton": ("Se connecter", "Sign in"),
    "authLoginNoAccount": ("Pas encore de compte ?", "Don't have an account?"),
    "authLoginSignup": ("S'inscrire", "Sign up"),
    "authSignupTitle": ("Inscription", "Sign up"),
    "authSignupButton": ("Créer mon compte", "Create my account"),
    "authSignupHasAccount": ("Déjà un compte ?", "Already have an account?"),
    "authSignupLogin": ("Se connecter", "Sign in"),
    "authOnboardingTitle": ("Bienvenue sur uniSaps", "Welcome to uniSaps"),
    "authOnboardingPseudo": ("Choisis ton pseudo", "Choose your username"),
    "authOnboardingPhoto": ("Photo de profil", "Profile photo"),
    "authOnboardingFinish": ("C'est parti !", "Let's go!"),
    "authTagline": ("Ton dressing intelligent", "Your smart wardrobe"),
    "authFillAllFields": ("Remplis tous les champs.", "Fill in all fields."),
    "authConnectionError": ("Erreur de connexion", "Connection error"),
    "authSignupError": ("Erreur lors de l'inscription", "Sign-up error"),
    "authPasswordsMismatch": (
        "Les mots de passe ne correspondent pas.",
        "Passwords do not match.",
    ),
    "authPasswordTooShort": (
        "Le mot de passe doit contenir au moins 6 caractères.",
        "Password must be at least 6 characters.",
    ),
    "authSignupCreateAccount": ("Créer un compte", "Create an account"),
    "authSignupJoin": ("Rejoins uniSaps", "Join uniSaps"),
    "authTabNormalAccount": ("Compte normal", "Standard account"),
    "authTabCreatorAccount": ("Compte créateur", "Creator account"),
    "authOnboardingWelcome": ("Bienvenue !", "Welcome!"),
    "authOnboardingConfigureProfile": (
        "Configure ton profil",
        "Set up your profile",
    ),
    "authOnboardingTakePhoto": ("Prendre une photo", "Take a photo"),
    "authOnboardingChooseGallery": (
        "Choisir depuis la galerie",
        "Choose from gallery",
    ),
    "authOnboardingAddPhoto": ("Ajouter une photo", "Add a photo"),
    "authOnboardingChooseUsername": (
        "Choisis un pseudo.",
        "Choose a username.",
    ),
    "authSignupSubmit": ("S'inscrire", "Sign up"),
    "authAlreadyHaveAccount": ("Déjà un compte ?", "Already have an account?"),
    "authGoLogin": ("Connexion", "Sign in"),
    # Categories
    "categoryHeadwear": ("Couvre-chef", "Headwear"),
    "categoryTop": ("Hauts", "Tops"),
    "categoryOuterwear": ("Vestes", "Outerwear"),
    "categoryBottom": ("Bas", "Bottoms"),
    "categoryShoes": ("Chaussures", "Shoes"),
    "categoryAccessory": ("Accessoires", "Accessories"),
    # Premium
    "premiumDialogTitle": ("UniSaps+", "UniSaps+"),
    "premiumDialogBenefit1": ("Analyse photo IA", "AI photo analysis"),
    "premiumDialogBenefit2": ("3 suggestions / matin", "3 suggestions each morning"),
    "premiumDialogBenefit3": ("Badge premium", "Premium badge"),
    "premiumDialogPriceMonthly": ("1 €/mois", "€1/month"),
    "premiumDialogPriceLifetime": ("5 € à vie", "€5 lifetime"),
    "premiumDialogCta": ("Voir UniSaps+", "See UniSaps+"),
    # Home / lock
    "lockTabAddGarment": (
        "Ajoute un vêtement à ton dressing pour débloquer cette section",
        "Add a garment to your wardrobe to unlock this section",
    ),
    "lockTabCreateOutfit": (
        "Crée ton premier outfit pour débloquer cette section",
        "Create your first outfit to unlock this section",
    ),
    "snackActionDressing": ("Dressing", "Wardrobe"),
    "snackActionOutfits": ("Outfits", "Outfits"),
    # Tutorial
    "tutorialDressingTitle": ("Commence par ton dressing", "Start with your wardrobe"),
    "tutorialDressingDesc": (
        "Ajoute un vêtement pour remplir ton dressing.",
        "Add a garment to fill your wardrobe.",
    ),
    "tutorialOutfitsTitle": ("Crée ton premier outfit", "Create your first outfit"),
    "tutorialOutfitsDesc": (
        "Assemble tes vêtements en un look complet.",
        "Combine your clothes into a complete look.",
    ),
    "tutorialInspoTitle": ("Inspire-toi et publie", "Get inspired and share"),
    "tutorialInspoDesc": (
        "Découvre les looks des autres et partage le tien.",
        "Discover others' looks and share yours.",
    ),
    "tutorialPublishTitle": ("Publie ton look du jour", "Share today's look"),
    "tutorialPublishDesc": (
        "Depuis Inspiration, partage la photo de ton outfit du jour (1 par jour).",
        "From Inspiration, share your outfit-of-the-day photo (one per day).",
    ),
    "tutorialProfileTitle": ("Ton profil", "Your profile"),
    "tutorialProfileDesc": (
        "Retrouve tes stats, ta galerie, tes amis et les paramètres de ton compte.",
        "Find your stats, gallery, friends, and account settings.",
    ),
    "tutorialInspoDiscoverDesc": (
        "Découvre les looks de la communauté et like ceux qui t'inspirent.",
        "Discover community looks and like the ones that inspire you.",
    ),
    # Dressing
    "dressingAddGarment": ("Ajouter un vêtement", "Add a garment"),
    "dressingEmptyTitle": ("Ton dressing est vide", "Your wardrobe is empty"),
    "dressingEmptyDesc": (
        "Ajoute ta première pièce pour commencer.",
        "Add your first item to get started.",
    ),
    "dressingNoResults": ("Aucun résultat", "No results"),
    "dressingNoGarments": ("Aucun vêtement", "No garments"),
    "dressingTryOtherFilters": (
        "Essaie un autre nom, marque ou couleur.",
        "Try another name, brand, or color.",
    ),
    "dressingAddFirstGarment": (
        "Ajoute ton premier vêtement !",
        "Add your first garment!",
    ),
    "dressingAddShort": ("Ajouter", "Add"),
    "dressingNewGarment": ("Nouveau vêtement", "New garment"),
    # Outfits
    "outfitsMorningTitle": ("Quel look pour aujourd'hui ?", "What look for today?"),
    "outfitsMorningSwipe": ("Swiper", "Swipe"),
    "outfitsMorningBiblio": ("Ma bibliothèque", "My library"),
    "outfitsMorningAi": ("Suggestions UniSaps+", "UniSaps+ suggestions"),
    "outfitsMorningSubtitle": (
        "Choisis comment parcourir tes tenues.",
        "Choose how to browse your outfits.",
    ),
    "outfitsMorningAiDiscover": (
        "Découvrir les suggestions UniSaps+",
        "Discover UniSaps+ suggestions",
    ),
    "outfitsAddFit": ("Ajouter un fit", "Add an outfit"),
    "outfitsModeSwipe": ("Swipe", "Swipe"),
    "outfitsModeBiblio": ("Biblio", "Library"),
    "outfitsChooseToday": ("Choisir pour aujourd'hui", "Choose for today"),
    # Inspiration
    "inspoFriends": ("Amis", "Friends"),
    "inspoExplore": ("Explorer", "Explore"),
    "inspoPublish": ("Publier", "Publish"),
    "inspoSponsored": ("Sponsorisé", "Sponsored"),
    "inspoEmptyFriends": (
        "Ajoute des amis pour voir leurs looks ici.",
        "Add friends to see their looks here.",
    ),
    "inspoEmptyExplore": (
        "Aucun post pour le moment.",
        "No posts yet.",
    ),
    # Profile
    "profileTabStats": ("Stats", "Stats"),
    "profileTabOutfits": ("Tenues", "Outfits"),
    "profileTabGallery": ("Galerie", "Gallery"),
    "profileTabAccount": ("Compte", "Account"),
    "profileFriendsSection": ("Amis", "Friends"),
    "profileSettingsSection": ("Paramètres", "Settings"),
    "profileFriendRequestSnack": ("Nouvelle demande d'ami", "New friend request"),
    "profileDeleteAccount": ("Supprimer le compte", "Delete account"),
    "profileDeleteIrreversible": (
        "Cette action est irréversible.",
        "This action cannot be undone.",
    ),
    "profilePrivateAccount": ("Compte privé", "Private account"),
    # Weather seasons
    "seasonWinter": ("Hiver", "Winter"),
    "seasonSpring": ("Printemps", "Spring"),
    "seasonSummer": ("Été", "Summer"),
    "seasonAutumn": ("Automne", "Autumn"),
    # Weather simple
    "weatherNice": ("Beau temps", "Nice weather"),
    "weatherCloudy": ("Nuageux", "Cloudy"),
    "weatherRain": ("Pluie", "Rain"),
    "weatherSnow": ("Neige", "Snow"),
    "weatherStorm": ("Orage", "Storm"),
    "weatherFog": ("Brouillard", "Fog"),
    "weatherPartlyClear": ("Partiellement dégagé", "Partly clear"),
    "weatherVariable": ("Variable", "Variable"),
    # Creation steps
    "creationStepPieces": ("Pièces", "Pieces"),
    "creationStepNamePhoto": ("Nom & photo", "Name & photo"),
    "creationStepWeather": ("Météo", "Weather"),
    "creationPiecesTitle": ("Pièces du look", "Outfit pieces"),
    "creationOutfitName": ("Nom de l'outfit", "Outfit name"),
    "creationPhotoRequired": (
        "Obligatoire pour créer un look",
        "Required to create a look",
    ),
    "creationWeatherLabel": ("Temps", "Weather"),
    "creationSeasonsLabel": ("Saisons", "Seasons"),
    "creationWeatherAll": ("Toutes les conditions", "All conditions"),
    "creationSeasonsAll": ("Toutes les saisons", "All seasons"),
    # Colors (display)
    "colorBlack": ("Noir", "Black"),
    "colorWhite": ("Blanc", "White"),
    "colorGrey": ("Gris", "Grey"),
    "colorLightGrey": ("Gris clair", "Light grey"),
    "colorDarkGrey": ("Gris foncé", "Dark grey"),
    "colorBeige": ("Beige", "Beige"),
    "colorCamel": ("Camel", "Camel"),
    "colorBrown": ("Marron", "Brown"),
    "colorBlue": ("Bleu", "Blue"),
    "colorRed": ("Rouge", "Red"),
    "colorGreen": ("Vert", "Green"),
    "colorYellow": ("Jaune", "Yellow"),
    "colorOrange": ("Orange", "Orange"),
    "colorPink": ("Rose", "Pink"),
    "colorMulticolor": ("Multicolore", "Multicolor"),
    "colorPurple": ("Violet", "Purple"),
    "colorMulticolor": ("Multicolore", "Multicolor"),
    "profileAccountPrivate": ("Privé", "Private"),
    "profileAccountPublic": ("Public", "Public"),
    "profilePremiumActive": ("Actif", "Active"),
    "profilePremiumFree": ("Gratuit", "Free"),
    "profileDarkModeSubtitle": (
        "Confort visuel en faible luminosité",
        "Comfort in low light",
    ),
    "profileMemberSince": ("Membre depuis", "Member since"),
    "profileBestStreak": ("Meilleur streak", "Best streak"),
    "profileDays": ("jours", "days"),
    "profileEmail": ("Email", "Email"),
    "profileUsername": ("Pseudo", "Username"),
    "profileDisplayName": ("Nom", "Name"),
    "profilePremiumCodeHint": ("Entre ton code UniSaps+", "Enter your UniSaps+ code"),
    "premiumDialogTitleFull": ("Passe en UniSaps+", "Upgrade to UniSaps+"),
    "premiumDialogBenefit1Full": (
        "Analyse IA de tes photos de vêtements",
        "AI analysis of your garment photos",
    ),
    "premiumDialogBenefit2Full": (
        "3 suggestions d'outfits chaque matin",
        "3 outfit suggestions every morning",
    ),
    "premiumDialogBenefit3Full": (
        "Badge premium sur ton profil",
        "Premium badge on your profile",
    ),
    "premiumDialogPriceMonthlyFull": ("1 € / mois", "€1 / month"),
    "premiumDialogPriceLifetimeFull": (
        "ou 5 € à vie (achat unique)",
        "or €5 lifetime (one-time)",
    ),
    "premiumDialogActivateHint": (
        "Active UniSaps+ depuis ton profil (onglet Compte).",
        "Activate UniSaps+ from your profile (Account tab).",
    ),
    "asyncErrorSubtitleLong": (
        "Vérifie ta connexion et réessaie dans quelques instants.",
        "Check your connection and try again in a moment.",
    ),
    "authLoginSignupLink": ("Inscription", "Sign up"),
    "authEmail": ("Email", "Email"),
    "authPassword": ("Mot de passe", "Password"),
    "authConfirmPassword": ("Confirmer le mot de passe", "Confirm password"),
    "authPseudo": ("Pseudo", "Username"),
    "authFullNameOptional": ("Nom complet (optionnel)", "Full name (optional)"),
    "dressingMyWardrobe": ("Mon Dressing", "My Wardrobe"),
    "garmentNoItemsInCategory": (
        "Aucun vêtement dans cette catégorie",
        "No garments in this category",
    ),
    "dressingFilterAll": ("Tout", "All"),
    "dressingNameHint": ("Nom", "Name"),
    "dressingFilterBrand": ("— Marque", "— Brand"),
    "dressingFilterColor": ("— Couleur", "— Color"),
    "garmentNameDescHint": ("Nom / description", "Name / description"),
    "garmentBrandHint": ("Marque", "Brand"),
    "garmentBrandTapAgainToFilter": (
        "Appuie à nouveau pour filtrer…",
        "Tap again to filter…",
    ),
    "garmentBrandNoneFound": (
        "Aucune marque trouvée",
        "No brand found",
    ),
    "garmentColorHint": ("Couleur", "Color"),
    "garmentColorMaxReached": (
        "Maximum 3 couleurs atteint",
        "Maximum of 3 colors reached",
    ),
    "garmentColorTapAgainToFilter": (
        "Taper à nouveau pour filtrer",
        "Tap again to filter",
    ),
    "garmentColorSearchHint": (
        "Rechercher une couleur…",
        "Search for a color…",
    ),
    "garmentColorNoneFound": (
        "Aucune couleur trouvée",
        "No color found",
    ),
    "garmentCategoryTitle": ("Catégorie", "Category"),
    "garmentAddPhotoCaption": ("Ajouter une photo", "Add a photo"),
    "garmentNameRequired": ("Le nom est obligatoire.", "Name is required."),
    "garmentSaveError": (
        "Erreur lors de l'enregistrement.",
        "Error while saving.",
    ),
    "garmentCollectionNameHint": ("Nom de la collection", "Collection name"),
    "garmentPrefillAi": ("Pré-remplir avec l'IA", "Pre-fill with AI"),
    "garmentAiSubtitle": (
        "Une seule analyse par ajout : la première photo (couleurs, catégorie, etc.).",
        "One analysis per add: first photo (colors, category, etc.).",
    ),
    "pickerCamera": ("Appareil photo", "Camera"),
    "pickerGallery": ("Galerie", "Gallery"),
    "inspoCaptionOptional": ("Légende (optionnel)...", "Caption (optional)…"),
    "inspoCaption": ("Légende...", "Caption…"),
    "inspoSearchUser": ("Rechercher un utilisateur...", "Search for a user…"),
    "inspoFeedFriends": ("Amis", "Friends"),
    "inspoFeedExplore": ("Explorer", "Explore"),
    "inspoFeedSemanticsPrefix": ("Fil Inspiration : ", "Inspiration feed: "),
    "inspoPublishToday": ("Publier mon look du jour", "Publish my look of the day"),
    "inspoOptions": ("Options", "Options"),
    "friendRequestPending": ("Aucune demande en attente", "No pending requests"),
    "friendWantsToBe": ("Veut être ton ami", "Wants to be your friend"),
    "searchTab": ("Rechercher", "Search"),
    "requestsTab": ("Demandes", "Requests"),
    "statWorn": ("Portés", "Worn"),
    "statStreak": ("Streak", "Streak"),
    "statBest": ("Best", "Best"),
    "userProfilePrivate": ("Privé", "Private"),
    "weatherRefresh": ("Actualiser à ma position", "Refresh to my location"),
    "weatherHourly": ("Heure par heure", "Hour by hour"),
    "weatherNow": ("En ce moment", "Right now"),
    "weatherHourNow": ("{hour}h", "{hour}h"),
    "weatherTodayMinMax": ("Auj. {range}", "Today {range}"),
    "weatherFeelsLike": ("Ressenti", "Feels like"),
    "weatherWind": ("Vent", "Wind"),
    "weatherHumidity": ("Humidité", "Humidity"),
    "weatherSunrise": ("Lever", "Sunrise"),
    "weatherSunset": ("Coucher", "Sunset"),
    "outfitsDeleteTooltip": ("Supprimer cet outfit", "Delete this outfit"),
    "outfitsWeatherTodayPrefix": ("Météo du jour, ", "Today's weather, "),
    "outfitsWeatherTodaySemantics": (
        "Météo du jour, {temp}°",
        "Today's weather, {temp}°",
    ),
    "outfitsStreakCount": ("{count}", "{count}"),
    "outfitsStreakPlusOne": ("+1", "+1"),
    "inspoPieceFallback": ("Pièce", "Piece"),
    "creationAddZone": ("Ajouter", "Add"),
    "deleteAccountTitle": ("Supprimer le compte", "Delete account"),
    "deleteAccountWarning": (
        "Cette action est irréversible. Toutes tes données seront supprimées définitivement.",
        "This action cannot be undone. All your data will be permanently deleted.",
    ),
    "deleteAccountConfirmPassword": (
        "Confirme avec ton mot de passe :",
        "Confirm with your password:",
    ),
    "deleteAccountConfirmButton": (
        "Supprimer définitivement",
        "Delete permanently",
    ),
    "deleteAccountError": (
        "Erreur lors de la suppression.",
        "Error while deleting account.",
    ),
    "creatorTabGarments": ("Vêtements", "Garments"),
    "creatorTabPosts": ("Posts", "Posts"),
    "creatorTabProfile": ("Profil", "Profile"),
    "creatorBrandName": ("Nom de la marque", "Brand name"),
    "creatorPublicId": ("@identifiant public", "Public @handle"),
    "creatorBio": ("Bio", "Bio"),
    "creatorShopUrl": ("Lien boutique (URL)", "Shop link (URL)"),
    "creatorPersonalAccount": ("@compte perso uniSaps (optionnel)", "Personal uniSaps @ (optional)"),
    "creatorProEmail": ("Email professionnel", "Business email"),
    "creatorActivationCode": ("Code d'activation", "Activation code"),
    "creatorPostName": ("Nom du post / look", "Post / look name"),
    "teasePremiumDiscover": ("Découvrir", "Discover"),
    "teasePremiumAiSuggestions": ("Suggestions IA", "AI suggestions"),
    "emptyFeedFriendsTitle": ("Aucun post d'amis", "No friends' posts"),
    "emptyFeedExploreTitle": ("Explore le feed", "Explore the feed"),
    # Profile (extra)
    "profileScrollMore": ("Fais défiler", "Scroll down"),
    "profilePremiumTooltip": ("Compte UniSaps+", "UniSaps+ account"),
    "profilePrivateTooltip": ("Profil privé", "Private profile"),
    "profileOneFriendRequestPending": (
        "Une demande d'ami en attente",
        "One pending friend request",
    ),
    "profileTabMemories": ("Souvenirs", "Memories"),
    "statGarments": ("Vêtements", "Garments"),
    "profileMostWornTitle": ("Les plus portes", "Most worn"),
    "profileNoOutfits": ("Aucun outfit", "No outfits"),
    "profileDefaultOutfitName": ("Outfit", "Outfit"),
    "profileLastWornPrefix": ("Dernier port : ", "Last worn: "),
    "profileWornPrefix": ("Porté ", "Worn "),
    "profileTimesSuffix": ("×", "×"),
    "profileNoGarmentsLinked": (
        "Aucun vêtement associé.",
        "No linked garments.",
    ),
    "profilePieceNotFound": ("Pièce introuvable", "Item not found"),
    "profileNoMemoriesYet": (
        "Aucun souvenir pour l'instant",
        "No memories yet",
    ),
    "profileMemoryPhotoHint": (
        "Photo prise lors du choix de l'outfit du jour.",
        "Photo taken when choosing today's outfit.",
    ),
    "profileReceivedRequests": ("Demandes reçues", "Received requests"),
    "profilePrivateFriendsOnly": (
        "Seuls tes amis voient ton contenu",
        "Only friends can see your content",
    ),
    "profilePrivateEveryone": (
        "Tout le monde peut voir ton contenu",
        "Everyone can see your content",
    ),
    "profileMyFriendsPrefix": ("Mes amis", "My friends"),
    "profileAddFriend": ("Ajouter un ami", "Add a friend"),
    "profileNoFriendsYet": (
        "Aucun ami pour le moment",
        "No friends yet",
    ),
    "profileRemoveFriendTitle": ("Retirer cet ami ?", "Remove this friend?"),
    "profileRemoveFriendBodyPrefix": (
        "Retirer @",
        "Remove @",
    ),
    "profileRemoveFriendBodySuffix": (
        " de ta liste d'amis ?",
        " from your friends list?",
    ),
    "profileViewProfile": ("Voir le profil", "View profile"),
    "profileIncorrectCode": ("Code incorrect.", "Incorrect code."),
    "profilePremiumActivatedSnack": (
        "UniSaps+ activé ! Profite des fonctionnalités IA.",
        "UniSaps+ activated! Enjoy AI features.",
    ),
    "profileErrorPrefix": ("Erreur : ", "Error: "),
    "profileActivateUniSaps": ("Activer UniSaps+", "Activate UniSaps+"),
    "profileLogOut": ("Se déconnecter", "Log out"),
    "profileIncorrectPassword": ("Mot de passe incorrect.", "Incorrect password."),
    "profileActivationCodeLabel": ("Code d'activation", "Activation code"),
    "profileFriendsLabel": ("Amis", "Friends"),
    "profileStreakDaysSuffix": (" jours", " days"),
    "profileBestStreakLine": ("Meilleur streak : ", "Best streak: "),
    "profileRemoveFriendAction": ("Retirer", "Remove"),
    # Inspiration (extra)
    "inspoScrollHint": (
        "Fais défiler pour parcourir les looks",
        "Scroll to browse looks",
    ),
    "inspoChooseOutfitFirst": (
        "Choisis d'abord ton outfit du jour",
        "Choose your outfit of the day first",
    ),
    "inspoOutfitNoLongerExists": (
        "Cet outfit n'existe plus. Choisis un outfit du jour.",
        "This outfit no longer exists. Choose today's outfit.",
    ),
    "inspoAddPhotoToPublish": (
        "Ajoute au moins une photo à ton outfit pour publier.",
        "Add at least one photo to your outfit to publish.",
    ),
    "inspoPreparePostError": (
        "Erreur lors de la préparation du post.",
        "Error preparing the post.",
    ),
    "inspoPublishTodayTitle": (
        "Publier l'outfit du jour",
        "Publish today's outfit",
    ),
    "inspoDefaultOutfitName": ("Mon outfit du jour", "My outfit of the day"),
    "inspoPublishedSnack": ("Outfit publié !", "Outfit published!"),
    "inspoAlreadyPostedSnack": (
        "Tu as déjà publié ton outfit aujourd'hui !",
        "You already published your outfit today!",
    ),
    "inspoPublishFailed": (
        "Erreur lors de la publication.",
        "Error while publishing.",
    ),
    "inspoFindFriends": ("Trouver des amis", "Find friends"),
    "emptyFeedFriendsNoFriendsTitle": (
        "Aucun ami pour le moment",
        "No friends yet",
    ),
    "emptyFeedFriendsNoFriendsSubtitle": (
        "Recherche des utilisateurs pour les ajouter !",
        "Search for users to add them!",
    ),
    "emptyFeedFriendsTodayTitle": (
        "Aucun post de tes amis aujourd'hui",
        "No friends' posts today",
    ),
    "emptyFeedFriendsTodaySubtitle": (
        "Reviens demain ou invite tes amis à publier.",
        "Come back tomorrow or invite friends to post.",
    ),
    "emptyFeedExploreEmptyTitle": (
        "Aucun post à explorer",
        "Nothing to explore yet",
    ),
    "emptyFeedExploreEmptySubtitle": (
        "Reviens plus tard pour découvrir de nouveaux looks.",
        "Come back later for new looks.",
    ),
    "inspoFeedEndTitle": (
        "Fin des posts du jour",
        "End of today's posts",
    ),
    "inspoFeedEndSubtitle": (
        "Reviens demain pour de nouveaux looks.",
        "Come back tomorrow for new looks.",
    ),
    "inspoEditCaptionTitle": ("Modifier la légende", "Edit caption"),
    "inspoCaptionVisibleHint": (
        "Texte visible sous la photo",
        "Text shown below the photo",
    ),
    "inspoDeletePostTitle": ("Supprimer le post", "Delete post"),
    "inspoDeletePostIrreversible": ("Irréversible", "Cannot be undone"),
    "inspoDeletePostConfirmTitle": (
        "Supprimer le post ?",
        "Delete this post?",
    ),
    "inspoDeletePostConfirmBody": (
        "Cette publication sera retirée du fil.",
        "This post will be removed from the feed.",
    ),
    "inspoDetails": ("Détails", "Details"),
    "inspoFitPieces": ("Pièces du fit", "Outfit pieces"),
    "inspoRequestsSection": ("Demandes", "Requests"),
    "inspoSearchTypeHint": (
        "Tape un nom pour chercher",
        "Type a name to search",
    ),
    "inspoSearchNoResults": ("Aucun résultat", "No results"),
    "inspoChipYou": ("Toi", "You"),
    "inspoFriendRequestSent": (
        "Demande envoyée à ",
        "Request sent to ",
    ),
    "inspoPostDeleted": ("Post supprimé.", "Post deleted."),
    "inspoPostDeleteFailed": (
        "Impossible de supprimer le post.",
        "Could not delete the post.",
    ),
    # Outfits (extra)
    "outfitsTodayTitle": ("Outfit du jour", "Outfit of the day"),
    "outfitsAiSuggestionsShort": ("Suggestions IA", "AI suggestions"),
    "outfitsPremiumRequiredAi": (
        "UniSaps+ requis pour les suggestions IA",
        "UniSaps+ required for AI suggestions",
    ),
    "outfitsCreateTooltip": ("Créer une tenue", "Create an outfit"),
    "outfitsAiSuggestionName": ("Suggestion IA", "AI suggestion"),
    "outfitsMyOutfitsTitle": ("Mes Outfits", "My Outfits"),
    "outfitsSwipeEmpty": (
        "Oups… Plus aucun choix d'outfits,\nOn recommence ?",
        "Oops… No more outfits to swipe.\nStart over?",
    ),
    "outfitsRestart": ("Recommencer", "Start over"),
    "outfitsGenerateError": (
        "Erreur lors de la génération",
        "Error while generating",
    ),
    "outfitsPrecisionHint": (
        "Précision (facultatif): ex. dîner chic, concert…",
        "Details (optional): e.g. chic dinner, concert…",
    ),
    "outfitsGenerating": ("Génération…", "Generating…"),
    "outfitsGenerateSuggestions": (
        "Générer des suggestions",
        "Generate suggestions",
    ),
    "outfitsLookLabel": ("Look ", "Look "),
    "outfitsPieceSingular": (" pièce", " piece"),
    "outfitsPiecePlural": (" pièces", " pieces"),
    "outfitsNoPiecesForSuggestion": (
        "Aucune pièce reconnue dans ton dressing pour cette suggestion.",
        "No items in your wardrobe match this suggestion.",
    ),
    "outfitsChooseThisLook": ("Choisir ce look", "Choose this look"),
    "outfitsForToday": ("Pour aujourd'hui", "For today"),
    "outfitsTodayBadge": ("Aujourd'hui", "Today"),
    "outfitsEmptyLibraryTitle": ("Aucun outfit", "No outfits"),
    "outfitsEmptyLibrarySubtitle": (
        "Crée ton premier look en ajoutant\nune photo et tes vêtements",
        "Create your first look by adding\na photo and your garments",
    ),
    "outfitsAddToLibrary": (
        "Ajouter un fit à la bibliothèque",
        "Add an outfit to the library",
    ),
    "outfitsTapForDetails": (
        "Tap pour voir les détails",
        "Tap to see details",
    ),
    "outfitsDayPhoto": ("Photo du jour", "Photo of the day"),
    "outfitsChangePhoto": ("Changer", "Change"),
    "outfitsDeleteOutfitTitle": (
        "Supprimer l'outfit ?",
        "Delete this outfit?",
    ),
    "outfitsDeleteOutfitBody": (
        "Cette action est irréversible.",
        "This action cannot be undone.",
    ),
    "outfitsStreakLine": ("Streak de ", "Streak: "),
    "outfitsStreakEncourage": (
        "Tu gardes la flamme, continue !",
        "Keep the streak going!",
    ),
    "outfitsStreakDaysSuffix": (" jours", " days"),
    # Creation (extra)
    "creationUploadError": (
        "Erreur lors de l'upload",
        "Upload error",
    ),
    "creationAddPhotoSheetTitle": (
        "Ajouter la photo de l'outfit",
        "Add outfit photo",
    ),
    "creationLayersHint": (
        "Tu peux ajouter plusieurs pièces — l'ordre suit celui de la liste (la première est la plus près du corps).",
        "You can add several items — order follows the list (first is closest to the body).",
    ),
    "creationNoGarmentInCategory": (
        "Aucun vêtement dans cette catégorie",
        "No garments in this category",
    ),
    "creationPieceAlreadyListed": (
        "Cette pièce est déjà dans la liste.",
        "This item is already in the list.",
    ),
    "creationAddOutfitPhotoSnack": (
        "Ajoute la photo de ton outfit.",
        "Add a photo of your outfit.",
    ),
    "creationNameRequiredSnack": (
        "Donne un nom à ton outfit.",
        "Give your outfit a name.",
    ),
    "creationSelectGarmentSnack": (
        "Sélectionne au moins un vêtement.",
        "Select at least one garment.",
    ),
    "creationCreatedSnack": ("Outfit créé !", "Outfit created!"),
    "creationCreateErrorSnack": (
        "Erreur lors de la création.",
        "Error while creating.",
    ),
    "creationTorsoLayersSubtitle": (
        "Plusieurs couches : à gauche, la plus près du corps.",
        "Multiple layers: leftmost is closest to the body.",
    ),
    "creationWristAccessoriesSubtitle": (
        "Ajoute autant d'accessoires que tu veux.",
        "Add as many accessories as you want.",
    ),
    "creationTorsoLayersTitle": (
        "Hauts (superposition)",
        "Tops (layering)",
    ),
    "creationNewLookTitle": ("Nouveau look", "New look"),
    "creationSaveButton": ("Sauver", "Save"),
    "creationUploading": ("Upload en cours...", "Uploading…"),
    "creationChangePhoto": ("Changer", "Change"),
    "creationAddPhotoPrompt": (
        "Ajoute la photo de ton outfit",
        "Add your outfit photo",
    ),
    "creationZoneHead": ("Tête", "Head"),
    "creationZoneJacket": ("Veste", "Jacket"),
    "creationZoneTorso": ("Haut", "Top"),
    "creationZoneLegs": ("Bas", "Bottom"),
    "creationZoneFeet": ("Chaussures", "Shoes"),
    "creationZoneWrist": ("Accessoire", "Accessory"),
    # Add garment sheet
    "garmentAiDescribeFailed": (
        "L'IA n'a pas pu décrire cette photo (service saturé ou image peu lisible). "
        "Tu peux remplir les champs manuellement ou réessayer avec une autre photo.",
        "AI could not describe this photo (busy service or unclear image). "
        "Fill in the fields manually or try another photo.",
    ),
    "garmentAiUnavailable": (
        "Analyse IA indisponible. Vérifie ta connexion et réessaie dans un instant.",
        "AI analysis unavailable. Check your connection and try again shortly.",
    ),
    "garmentTakePhoto": ("Prendre une photo", "Take a photo"),
    "garmentGalleryMultiple": (
        "Galerie - plusieurs photos",
        "Gallery — multiple photos",
    ),
    "garmentImageNotRecognizedTitle": (
        "Image non reconnue",
        "Image not recognized",
    ),
    "garmentImageNotRecognizedBody": (
        "L'IA n'a pas reconnu de vêtement, chaussure ou accessoire sur cette photo. "
        "Choisis une autre image plus claire montrant la pièce que tu veux ajouter.",
        "AI did not detect clothing, shoes, or an accessory in this photo. "
        "Choose a clearer image showing the item you want to add.",
    ),
    "garmentNameRequired": ("Le nom est obligatoire.", "Name is required."),
    "garmentCreatorPseudoMissing": (
        "Ton pseudo (@identifiant) est introuvable. Complète ton profil créateur.",
        "Your @handle was not found. Complete your creator profile.",
    ),
    "garmentCollectionNameRequired": (
        "Le nom de la collection est obligatoire.",
        "Collection name is required.",
    ),
    "garmentSelectCollection": (
        "Sélectionne une collection.",
        "Select a collection.",
    ),
    "garmentCollectionCreateFailed": (
        "Impossible de créer la collection.",
        "Could not create the collection.",
    ),
    "garmentServerUnreachable": (
        "Le serveur est inaccessible. Réessaie dans un instant.",
        "Server unreachable. Try again shortly.",
    ),
    "garmentAddedSnack": ("Vêtement ajouté !", "Garment added!"),
    "garmentUpdatedSnack": ("Vêtement modifié !", "Garment updated!"),
    "garmentSaveError": (
        "Erreur lors de l'enregistrement.",
        "Error while saving.",
    ),
    "garmentUploadTimeout": (
        "Le traitement d'une image prend trop de temps. Vérifie que le backend est démarré et patiente.",
        "Image processing is taking too long. Ensure the backend is running and wait.",
    ),
    "garmentServerContactFailed": (
        "Impossible de contacter le serveur. Réessaie dans un instant.",
        "Could not reach the server. Try again shortly.",
    ),
    "garmentFirebaseConfigMissing": (
        "Configuration Firebase manquante. Vérifie le fichier serviceAccountKey.json dans backend/",
        "Missing Firebase configuration. Check serviceAccountKey.json in backend/",
    ),
    "garmentStoragePermissions": (
        "Le serveur n'a pas les droits pour enregistrer l'image sur Firebase Storage. "
        "Dans Google Cloud Console → IAM, attribue au compte de service du backend "
        "le rôle Storage Admin ou Storage Object Creator.",
        "The server lacks permission to save images to Firebase Storage. "
        "In Google Cloud Console → IAM, grant the backend service account "
        "Storage Admin or Storage Object Creator.",
    ),
    "garmentSessionExpired": (
        "Session expirée ou jeton invalide. Déconnecte-toi, reconnecte-toi, puis réessaie.",
        "Session expired or invalid token. Sign out, sign in again, then retry.",
    ),
    "garmentAccessDenied": (
        "Accès refusé par le serveur. Si tu viens de te connecter, réessaie dans quelques secondes ; sinon préviens le support.",
        "Access denied by the server. If you just signed in, retry in a few seconds; otherwise contact support.",
    ),
    "garmentChooseCollection": (
        "Choisir une collection",
        "Choose a collection",
    ),
    "garmentCreateCollectionFirst": (
        "Crée d'abord une collection depuis ton catalogue marque.",
        "Create a collection from your brand catalog first.",
    ),
    "garmentCollectionExisting": ("Existante", "Existing"),
    "garmentCollectionNew": ("Nouvelle", "New"),
    "garmentCollectionsErrorPrefix": ("Collections : ", "Collections: "),
    "garmentAddPhotosTitle": (
        "Ajouter une ou plusieurs photos",
        "Add one or more photos",
    ),
    "garmentRemoveBackground": (
        "Supprimer l'arrière-plan",
        "Remove background",
    ),
    "garmentRemoveBackgroundHint": (
        "Utilise l'IA pour isoler le vêtement. Décoche si tu veux garder le fond.",
        "Uses AI to isolate the garment. Uncheck to keep the background.",
    ),
    "garmentEditTitle": (
        "Modifier le vêtement",
        "Edit garment",
    ),
    "garmentAddMorePhotos": (
        "Ajouter d'autres photos",
        "Add more photos",
    ),
    "garmentColorsLabel": ("Couleurs", "Colors"),
    "garmentCategoryLabel": ("Catégorie", "Category"),
    "garmentSaving": ("Enregistrement…", "Saving…"),
    "garmentSaveGarment": (
        "Enregistrer le vêtement",
        "Save garment",
    ),
    "garmentUpdateGarment": (
        "Mettre à jour",
        "Update",
    ),
    "garmentAddToDressing": (
        "Ajouter au dressing",
        "Add to wardrobe",
    ),
    "garmentCollectionSection": ("Collection", "Collection"),
    "garmentDateStartHint": ("Début (AAAA-MM-JJ)", "Start (YYYY-MM-DD)"),
    "garmentDateEndHint": ("Fin (AAAA-MM-JJ)", "End (YYYY-MM-DD)"),
    "garmentAiAnalyzingImages": (
        "Analyse des images par l'IA…",
        "Analyzing images with AI…",
    ),
    "garmentSaveButton": ("Enregistrer", "Save"),
    "garmentEditButton": ("Modifier", "Edit"),
    "garmentAnalyzing": ("Analyse IA en cours…", "AI analysis in progress…"),
    "profileStreakShort": ("j. série", "day streak"),
    "profileFriendLabel": ("ami", "friend"),
    "profileFriendsLabel": ("amis", "friends"),
    "profileFriendRequestsPending": (
        "demandes d'amis en attente",
        "pending friend requests",
    ),
    # Outfit style chips (API values stay French/canonical; labels localized)
    "styleSimple": ("Simple", "Simple"),
    "styleColorful": ("Coloré", "Colorful"),
    "styleClassy": ("Classe", "Classy"),
    "styleProfessional": ("Professionnel", "Professional"),
    "styleCasual": ("Décontracté", "Casual"),
    "styleStreetwear": ("Streetwear", "Streetwear"),
    "styleSporty": ("Sportif", "Sporty"),
    "styleEvening": ("Soirée", "Evening"),
    "outfitsStreakDialogBarrier": (
        "Célébration de streak",
        "Streak celebration",
    ),
    # Creator landing
    "creatorLandingTitle": ("Espace marque", "Brand space"),
    "creatorLandingDesc": (
        "Présente ton catalogue sur uniSaps : collections, vêtements et publications sponsorisées visibles dans le fil Inspiration des utilisateurs.",
        "Showcase your catalog on uniSaps: collections, garments, and sponsored posts visible in users' Inspiration feed.",
    ),
    "creatorBackToLogin": ("Retour à la connexion", "Back to sign in"),
    # Search users
    "searchSuggestionsTitle": ("Suggestions", "Suggestions"),
    "searchMutualFriends": ("amis en commun", "mutual friends"),
    "searchNoSuggestions": (
        "Aucune suggestion pour le moment",
        "No suggestions right now",
    ),
    "searchNoResultsShort": ("Aucun résultat", "No results"),
    "searchTypePseudo": (
        "Tape un pseudo pour chercher",
        "Type a username to search",
    ),
    "searchSuggestionsForYou": (
        "Suggestions pour toi",
        "Suggestions for you",
    ),
    "searchFriendsSuggestions": (
        "Suggestions d'amis",
        "Friend suggestions",
    ),
    "searchFriendsOfFriends": (
        "Amis d'amis et profils similaires",
        "Friends of friends and similar profiles",
    ),
    "searchRandomSuggestion": ("Suggestion aléatoire", "Random suggestion"),
    "searchMutualFriendSingular": ("ami en commun", "mutual friend"),
    "searchMutualFriendsPlural": ("amis en commun", "mutual friends"),
    # Weather detail
    "weatherClose": ("Fermer", "Close"),
    "weatherFeelsLikeShort": ("Ressenti", "Feels like"),
    "weatherSunCourse": ("Course du soleil", "Sun path"),
    "weatherNightInProgress": ("Nuit en cours", "Night in progress"),
    "weatherHourlyUnavailable": (
        "Données horaires indisponibles.",
        "Hourly data unavailable.",
    ),
    "weatherNoRainToday": ("Aucune pluie prévue aujourd'hui.", "No rain expected today."),
    "weatherModerateRainRisk": (
        "Risque modéré de pluie (max {pop} %).",
        "Moderate rain risk (max {pop}%).",
    ),
    "weatherRainLikelyFrom": (
        "Pluie probable à partir de {time} (max {pop} %, ~{mm} mm).",
        "Rain likely from {time} (max {pop}%, ~{mm} mm).",
    ),
    "weatherApproxPositionUpdated": (
        "Position approximative - mis à jour à {time}",
        "Approximate location - updated at {time}",
    ),
    "weatherOpenMeteoUpdated": (
        "Données Open-Meteo - mis à jour à {time}",
        "Open-Meteo data - updated at {time}",
    ),
    "weatherLoadingLocation": (
        "Localisation et récupération de la météo…",
        "Getting location and weather…",
    ),
    "weatherFetchFailed": (
        "Impossible de récupérer la météo.",
        "Could not fetch weather.",
    ),
    "weatherLocationParis": ("Paris (approx.)", "Paris (approx.)"),
    "weatherLocationPosition": ("Position", "Position"),
    # Shared (extra)
    "commonCreate": ("Créer", "Create"),
    "authNotConnected": ("Non connecté", "Not signed in"),
    "authSignOut": ("Déconnexion", "Sign out"),
    "commonErrorDetail": ("Erreur : {error}", "Error: {error}"),
    "garmentMaxThreeColors": (
        "Maximum 3 couleurs autorisées",
        "Maximum 3 colors allowed",
    ),
    "garmentDeleteConfirmTitle": (
        "Supprimer ce vêtement ?",
        "Delete this garment?",
    ),
    "garmentCollectionNameRequiredSnack": (
        "Indique un nom de collection.",
        "Enter a collection name.",
    ),
    "garmentDeleteCollectionTitle": (
        "Supprimer la collection ?",
        "Delete this collection?",
    ),
    "garmentCollectionDeleted": (
        "Collection supprimée.",
        "Collection deleted.",
    ),
    "garmentCollectionDeleteFailed": (
        "Suppression impossible.",
        "Could not delete.",
    ),
    "garmentCollectionDeleteWithPieces": (
        "« {name} » et ses {count} pièces seront supprimées définitivement.",
        "“{name}” and its {count} items will be permanently deleted.",
    ),
    "garmentCollectionDeleteWithPiece": (
        "« {name} » et sa pièce seront supprimées définitivement.",
        "“{name}” and its item will be permanently deleted.",
    ),
    "garmentCollectionDeleteOnly": (
        "« {name} » sera supprimée.",
        "“{name}” will be deleted.",
    ),
    "garmentCollectionNew": ("Nouvelle collection", "New collection"),
    "garmentCollectionStartDate": ("Date de début", "Start date"),
    "garmentCollectionEndDate": ("Date de fin", "End date"),
    "creatorCatalogTitle": ("Catalogue marque", "Brand catalog"),
    "creatorCatalogEmptyHint": (
        "Crée une collection pour organiser ton catalogue.",
        "Create a collection to organize your catalog.",
    ),
    "creatorNewCollectionTooltip": ("Nouvelle collection", "New collection"),
    # User profile (other user)
    "userProfileNotFound": ("Utilisateur introuvable", "User not found"),
    "userProfileFriend": ("Ami", "Friend"),
    "userProfileRequestSent": ("Demande envoyée", "Request sent"),
    "userProfileAccept": ("Accepter", "Accept"),
    "userProfileAddFriend": ("Ajouter en ami", "Add friend"),
    "userProfileFriendsLoadFailed": (
        "Impossible de charger la liste : {error}",
        "Could not load list: {error}",
    ),
    "userProfileNoFriendsYet": (
        "Aucun ami pour le moment",
        "No friends yet",
    ),
    "userProfilePending": ("En attente", "Pending"),
    "userProfileNoPosts": ("Aucun post", "No posts"),
    "userProfileEmptyDressing": ("Dressing vide", "Empty wardrobe"),
    "userProfileOtherPhotos": ("Autres photos", "Other photos"),
    "userProfileNoLinkedPieces": (
        "Aucune pièce liée",
        "No linked pieces",
    ),
    "userProfilePieces": ("Pièces", "Pieces"),
    "userProfileTimesWorn": ("{count}x porté", "Worn {count}×"),
    "inspoFriendRequestSentExclaim": (
        "Demande envoyée à @{username} !",
        "Friend request sent to @{username}!",
    ),
    # Creator profile
    "creatorShopLinkCopied": ("Lien boutique copié", "Shop link copied"),
    "creatorSubscriptionActive": ("Abonnement actif", "Active subscription"),
    "creatorSubscriptionInactive": (
        "Abonnement inactif",
        "Inactive subscription",
    ),
    "creatorSubscriptionExpires": ("Expire le {date}", "Expires on {date}"),
    "creatorSubscriptionRate": ("Tarif : {price}", "Price: {price}"),
    "creatorShopTitle": ("Boutique", "Shop"),
    "creatorViewPersonalProfile": (
        "Voir mon profil perso",
        "View my personal profile",
    ),
    # Creator onboarding
    "creatorOnboardingBrandRequired": (
        "Nom de marque et identifiant requis.",
        "Brand name and handle are required.",
    ),
    "creatorOnboardingLogoRequired": (
        "Ajoute un logo pour ta marque.",
        "Add a logo for your brand.",
    ),
    "creatorOnboardingTitle": ("Profil marque", "Brand profile"),
    "creatorLogoLabel": ("Logo de la marque", "Brand logo"),
    "creatorOnboardingFinish": ("Terminer", "Finish"),
    # Creator checkout
    "creatorCheckoutTitle": ("Abonnement marque", "Brand subscription"),
    "creatorSubscriptionMonthlyPrice": ("29 $ / mois", "29 $ / month"),
    "creatorCheckoutActivate": (
        "Activer mon espace marque",
        "Activate my brand space",
    ),
    # Creator posts
    "creatorPostPubLabel": ("Post pub", "Sponsored post"),
    "creatorPostsTitle": ("Posts publicitaires", "Sponsored posts"),
    "creatorPostsEmpty": ("Aucun post pour l'instant.", "No posts yet."),
    # Creator post create
    "creatorPostPublishedSnack": (
        "Post publicitaire publié.",
        "Sponsored post published.",
    ),
    "creatorNewPostPub": ("Nouveau post pub", "New sponsored post"),
    "creatorPostCollectionLabel": ("Collection", "Collection"),
    "creatorPostCollectionsError": (
        "Collections : {error}",
        "Collections: {error}",
    ),
    "creatorPostVisibleInFeed": (
        "Visible dans le feed (actif)",
        "Visible in feed (active)",
    ),
    "creatorPostFeedPreview": ("Aperçu feed", "Feed preview"),
    "creatorPostCaptionLabel": ("Légende (optionnel)", "Caption (optional)"),
    "creatorPostsFilterAll": ("Toutes", "All"),
    "creatorStatPerformance": ("Performance", "Performance"),
    "creatorStatActive": ("Actifs", "Active"),
    "creatorStatViews": ("Vues", "Views"),
    "creatorStatLikes": ("Likes", "Likes"),
    "garmentDeleteCollectionAction": (
        "Supprimer la collection",
        "Delete collection",
    ),
    "userProfileCollections": ("Collections", "Collections"),
    "userProfileAddedOn": ("Ajoutée le {date}", "Added on {date}"),
    "colorFilterTypeHint": ("Taper pour filtrer", "Type to filter"),
    "profileMemberLabel": ("Membre", "Member"),
    # Signup creator tab
    "signupCreatorForBrands": (
        "Pour les marques & créateurs",
        "For brands & creators",
    ),
    "signupCreatorSpaceTitle": ("Espace créateur", "Creator space"),
    "signupCreatorIntro": (
        "Ton univers marque s'affiche là où les gens découvrent déjà des styles : "
        "même fil que les utilisateurs, avec ta boutique et tes publications.",
        "Your brand shows up where people already discover styles: "
        "the same feed as users, with your shop and posts.",
    ),
    "signupCreatorSwipeRight": ("Glisse vers la droite", "Swipe right"),
    "signupCreatorCard1Title": (
        "Le même geste qu'Inspiration",
        "Same gesture as Inspiration",
    ),
    "signupCreatorCard1Body": (
        "Les utilisateurs font défiler des cartes : looks, profils, créateurs. "
        "Ta marque apparaît dans ce flux — un swipe vers la droite, comme pour "
        "montrer son intérêt sur une tenue.",
        "Users swipe through cards: looks, profiles, creators. "
        "Your brand appears in that feed — a right swipe, like showing interest in an outfit.",
    ),
    "signupCreatorCard2Title": (
        "Catalogue & dressing marque",
        "Brand catalog & wardrobe",
    ),
    "signupCreatorCard2Body": (
        "Tu exposes tes pièces et tenues dans un espace dédié : ton dressing "
        "pro, séparé des comptes perso, toujours relié au reste de l'app.",
        "Showcase your pieces and outfits in a dedicated space: your pro wardrobe, "
        "separate from personal accounts, still connected to the rest of the app.",
    ),
    "signupCreatorCard3Title": (
        "Visibilité & publications",
        "Visibility & posts",
    ),
    "signupCreatorCard3Body": (
        "Mets en avant une collection ou une pièce avec des posts sponsorisés : "
        "tu captes l'attention au bon endroit, sans changer les habitudes des gens.",
        "Highlight a collection or item with sponsored posts: "
        "grab attention in the right place without changing how people use the app.",
    ),
    "signupCreatorCreateAccount": (
        "Créer mon compte",
        "Create my account",
    ),
    "signupCreatorBrandNextPage": (
        "Inscription marque sur la page suivante",
        "Brand sign-up on the next page",
    ),
    "signupCreatorAlreadyAccount": ("Déjà un compte ?", "Already have an account?"),
    "signupCreatorSwipeRightBadge": ("Swipe droite", "Swipe right"),
    "signupCreatorCatalogPieces": ("Pièces", "Pieces"),
    "signupCreatorCatalogOutfits": ("Tenues", "Outfits"),
    "creatorPostsNoCollection": ("Sans collection", "No collection"),
    "creatorCheckoutSimulatedPayment": (
        "Paiement simulé en développement. Saisis le code d'activation pour activer ton espace.",
        "Simulated payment in development. Enter the activation code to activate your space.",
    ),
    "creatorActivationCodeInvalid": (
        "Code d'activation invalide.",
        "Invalid activation code.",
    ),
    "creatorCheckoutEmailPasswordRequired": (
        "Email et mot de passe (6 car. min.) requis.",
        "Email and password (6 char. min.) required.",
    ),
    "authSignupFailed": ("Inscription impossible.", "Sign-up failed."),
    "creatorPostPublishFailed": (
        "Publication impossible.",
        "Could not publish.",
    ),
    "userProfilePrivateViewBody": (
        "Ajoute cet utilisateur en ami pour voir son contenu.",
        "Add this user as a friend to see their content.",
    ),
    "userProfileFriendsOf": (
        "Amis de @{username}",
        "Friends of @{username}",
    ),
    # API error codes (backend error_code → l10n)
    "apiInvalidFirebaseToken": (
        "Session expirée. Reconnecte-toi.",
        "Session expired. Please sign in again.",
    ),
    "apiGarmentNotFound": ("Vêtement introuvable.", "Garment not found."),
    "apiOutfitNotFound": ("Outfit introuvable.", "Outfit not found."),
    "apiPostNotFound": ("Post introuvable.", "Post not found."),
    "apiUserNotFound": ("Utilisateur introuvable.", "User not found."),
    "apiActionNotAllowed": ("Action non autorisée.", "Action not allowed."),
    "apiCannotAddSelf": (
        "Impossible de t'ajouter toi-même.",
        "You can't add yourself.",
    ),
    "apiFriendRequestAlreadySent": (
        "Demande déjà envoyée.",
        "Request already sent.",
    ),
    "apiFriendRequestNotFound": (
        "Demande introuvable.",
        "Request not found.",
    ),
    "apiFriendRequestAlreadyHandled": (
        "Demande déjà traitée.",
        "Request already handled.",
    ),
    "apiInvalidActivationCode": (
        "Code d'activation invalide.",
        "Invalid activation code.",
    ),
    "apiEmptyFile": ("Fichier vide.", "Empty file."),
    "apiUnknownError": ("Une erreur est survenue.", "Something went wrong."),
    "apiNotAuthenticated": (
        "Utilisateur non authentifié.",
        "User not authenticated.",
    ),
    "apiConnectionError": (
        "Impossible de contacter le serveur.",
        "Could not reach the server.",
    ),
    "apiUploadTimeout": (
        "Le traitement de l'image prend trop de temps.",
        "Image processing is taking too long.",
    ),
    "apiInvalidServerResponse": (
        "Réponse invalide du serveur.",
        "Invalid server response.",
    ),
    "apiSuggestError": ("Erreur API.", "API error."),
    "apiAnalyzeError": ("Erreur analyse IA.", "AI analysis error."),
    "apiUploadError": ("Erreur lors de l'upload.", "Upload error."),
    "garmentImageNamesMismatch": (
        "Incohérence images / noms de fichiers.",
        "Image / filename count mismatch.",
    ),
    "garmentNewImageNamesMismatch": (
        "Incohérence nouvelles images / noms de fichiers.",
        "New image / filename count mismatch.",
    ),
    "authNoUserConnected": (
        "Aucun utilisateur connecté.",
        "No user signed in.",
    ),
    "postInvalidId": (
        "ID du post invalide.",
        "Invalid post ID.",
    ),
    "userAtUsername": ("@{username}", "@{username}"),
}

def slug(s: str) -> str:
    s = re.sub(r"[^\w\s]", "", s.lower())
    s = re.sub(r"\s+", "_", s.strip())[:40]
    return s or "key"

def write_arb(path: Path, locale: str, lang_idx: int):
    data = {"@@locale": locale}
    for key, pair in sorted(CATALOG.items()):
        data[key] = pair[lang_idx]
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")

write_arb(ROOT / "app_fr.arb", "fr", 0)
write_arb(ROOT / "app_en.arb", "en", 1)
print(f"Wrote {len(CATALOG)} keys to ARB files")
