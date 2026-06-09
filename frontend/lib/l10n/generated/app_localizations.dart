import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'uniSaps'**
  String get appTitle;

  /// No description provided for @asyncErrorSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta connexion et réessaie.'**
  String get asyncErrorSubtitle;

  /// No description provided for @asyncErrorSubtitleLong.
  ///
  /// In fr, this message translates to:
  /// **'Vérifie ta connexion et réessaie dans quelques instants.'**
  String get asyncErrorSubtitleLong;

  /// No description provided for @asyncErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger'**
  String get asyncErrorTitle;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get authConfirmPassword;

  /// No description provided for @authConnectionError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de connexion'**
  String get authConnectionError;

  /// No description provided for @authEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get authEmail;

  /// No description provided for @authFillAllFields.
  ///
  /// In fr, this message translates to:
  /// **'Remplis tous les champs.'**
  String get authFillAllFields;

  /// No description provided for @authFullNameOptional.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet (optionnel)'**
  String get authFullNameOptional;

  /// No description provided for @authGoLogin.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get authGoLogin;

  /// No description provided for @authLoginButton.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authLoginButton;

  /// No description provided for @authLoginEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get authLoginEmail;

  /// No description provided for @authLoginNoAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get authLoginNoAccount;

  /// No description provided for @authLoginPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authLoginPassword;

  /// No description provided for @authLoginSignup.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get authLoginSignup;

  /// No description provided for @authLoginSignupLink.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get authLoginSignupLink;

  /// No description provided for @authLoginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get authLoginTitle;

  /// No description provided for @authNotConnected.
  ///
  /// In fr, this message translates to:
  /// **'Non connecté'**
  String get authNotConnected;

  /// No description provided for @authOnboardingAddPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get authOnboardingAddPhoto;

  /// No description provided for @authOnboardingChooseGallery.
  ///
  /// In fr, this message translates to:
  /// **'Choisir depuis la galerie'**
  String get authOnboardingChooseGallery;

  /// No description provided for @authOnboardingChooseUsername.
  ///
  /// In fr, this message translates to:
  /// **'Choisis un pseudo.'**
  String get authOnboardingChooseUsername;

  /// No description provided for @authOnboardingConfigureProfile.
  ///
  /// In fr, this message translates to:
  /// **'Configure ton profil'**
  String get authOnboardingConfigureProfile;

  /// No description provided for @authOnboardingFinish.
  ///
  /// In fr, this message translates to:
  /// **'C\'est parti !'**
  String get authOnboardingFinish;

  /// No description provided for @authOnboardingPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo de profil'**
  String get authOnboardingPhoto;

  /// No description provided for @authOnboardingPseudo.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ton pseudo'**
  String get authOnboardingPseudo;

  /// No description provided for @authOnboardingTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get authOnboardingTakePhoto;

  /// No description provided for @authOnboardingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue sur uniSaps'**
  String get authOnboardingTitle;

  /// No description provided for @authOnboardingWelcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue !'**
  String get authOnboardingWelcome;

  /// No description provided for @authPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get authPassword;

  /// No description provided for @authPasswordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 6 caractères.'**
  String get authPasswordTooShort;

  /// No description provided for @authPasswordsMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas.'**
  String get authPasswordsMismatch;

  /// No description provided for @authPseudo.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo'**
  String get authPseudo;

  /// No description provided for @authSignOut.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get authSignOut;

  /// No description provided for @authSignupButton.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get authSignupButton;

  /// No description provided for @authSignupCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer un compte'**
  String get authSignupCreateAccount;

  /// No description provided for @authSignupError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'inscription'**
  String get authSignupError;

  /// No description provided for @authSignupFailed.
  ///
  /// In fr, this message translates to:
  /// **'Inscription impossible.'**
  String get authSignupFailed;

  /// No description provided for @authSignupHasAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get authSignupHasAccount;

  /// No description provided for @authSignupJoin.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins uniSaps'**
  String get authSignupJoin;

  /// No description provided for @authSignupLogin.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get authSignupLogin;

  /// No description provided for @authSignupSubmit.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get authSignupSubmit;

  /// No description provided for @authSignupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inscription'**
  String get authSignupTitle;

  /// No description provided for @authTabCreatorAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte créateur'**
  String get authTabCreatorAccount;

  /// No description provided for @authTabNormalAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte normal'**
  String get authTabNormalAccount;

  /// No description provided for @authTagline.
  ///
  /// In fr, this message translates to:
  /// **'Ton dressing intelligent'**
  String get authTagline;

  /// No description provided for @categoryAccessory.
  ///
  /// In fr, this message translates to:
  /// **'Accessoires'**
  String get categoryAccessory;

  /// No description provided for @categoryBottom.
  ///
  /// In fr, this message translates to:
  /// **'Bas'**
  String get categoryBottom;

  /// No description provided for @categoryHeadwear.
  ///
  /// In fr, this message translates to:
  /// **'Couvre-chef'**
  String get categoryHeadwear;

  /// No description provided for @categoryOuterwear.
  ///
  /// In fr, this message translates to:
  /// **'Vestes'**
  String get categoryOuterwear;

  /// No description provided for @categoryShoes.
  ///
  /// In fr, this message translates to:
  /// **'Chaussures'**
  String get categoryShoes;

  /// No description provided for @categoryTop.
  ///
  /// In fr, this message translates to:
  /// **'Hauts'**
  String get categoryTop;

  /// No description provided for @colorBeige.
  ///
  /// In fr, this message translates to:
  /// **'Beige'**
  String get colorBeige;

  /// No description provided for @colorBlack.
  ///
  /// In fr, this message translates to:
  /// **'Noir'**
  String get colorBlack;

  /// No description provided for @colorBlue.
  ///
  /// In fr, this message translates to:
  /// **'Bleu'**
  String get colorBlue;

  /// No description provided for @colorBrown.
  ///
  /// In fr, this message translates to:
  /// **'Marron'**
  String get colorBrown;

  /// No description provided for @colorCamel.
  ///
  /// In fr, this message translates to:
  /// **'Camel'**
  String get colorCamel;

  /// No description provided for @colorDarkGrey.
  ///
  /// In fr, this message translates to:
  /// **'Gris foncé'**
  String get colorDarkGrey;

  /// No description provided for @colorGreen.
  ///
  /// In fr, this message translates to:
  /// **'Vert'**
  String get colorGreen;

  /// No description provided for @colorGrey.
  ///
  /// In fr, this message translates to:
  /// **'Gris'**
  String get colorGrey;

  /// No description provided for @colorLightGrey.
  ///
  /// In fr, this message translates to:
  /// **'Gris clair'**
  String get colorLightGrey;

  /// No description provided for @colorMulticolor.
  ///
  /// In fr, this message translates to:
  /// **'Multicolore'**
  String get colorMulticolor;

  /// No description provided for @colorOrange.
  ///
  /// In fr, this message translates to:
  /// **'Orange'**
  String get colorOrange;

  /// No description provided for @colorPink.
  ///
  /// In fr, this message translates to:
  /// **'Rose'**
  String get colorPink;

  /// No description provided for @colorPurple.
  ///
  /// In fr, this message translates to:
  /// **'Violet'**
  String get colorPurple;

  /// No description provided for @colorRed.
  ///
  /// In fr, this message translates to:
  /// **'Rouge'**
  String get colorRed;

  /// No description provided for @colorWhite.
  ///
  /// In fr, this message translates to:
  /// **'Blanc'**
  String get colorWhite;

  /// No description provided for @colorYellow.
  ///
  /// In fr, this message translates to:
  /// **'Jaune'**
  String get colorYellow;

  /// No description provided for @commonAdd.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get commonAdd;

  /// No description provided for @commonAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get commonAll;

  /// No description provided for @commonBack.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get commonBack;

  /// No description provided for @commonCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get commonConfirm;

  /// No description provided for @commonCreate.
  ///
  /// In fr, this message translates to:
  /// **'Créer'**
  String get commonCreate;

  /// No description provided for @commonDelete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get commonEdit;

  /// No description provided for @commonError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get commonError;

  /// No description provided for @commonErrorDetail.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : {error}'**
  String commonErrorDetail(Object error);

  /// No description provided for @commonLater.
  ///
  /// In fr, this message translates to:
  /// **'Plus tard'**
  String get commonLater;

  /// No description provided for @commonLoading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement…'**
  String get commonLoading;

  /// No description provided for @commonNext.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get commonNext;

  /// No description provided for @commonNo.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get commonNo;

  /// No description provided for @commonOk.
  ///
  /// In fr, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get commonPrevious;

  /// No description provided for @commonPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get commonPublish;

  /// No description provided for @commonRetry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get commonRetry;

  /// No description provided for @commonSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get commonSave;

  /// No description provided for @commonSearch.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get commonSearch;

  /// No description provided for @commonShare.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get commonShare;

  /// No description provided for @commonSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get commonSkip;

  /// No description provided for @commonYes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get commonYes;

  /// No description provided for @creationAddOutfitPhotoSnack.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute la photo de ton outfit.'**
  String get creationAddOutfitPhotoSnack;

  /// No description provided for @creationAddPhotoPrompt.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute la photo de ton outfit'**
  String get creationAddPhotoPrompt;

  /// No description provided for @creationAddPhotoSheetTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter la photo de l\'outfit'**
  String get creationAddPhotoSheetTitle;

  /// No description provided for @creationAddZone.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get creationAddZone;

  /// No description provided for @creationChangePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get creationChangePhoto;

  /// No description provided for @creationCreateErrorSnack.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la création.'**
  String get creationCreateErrorSnack;

  /// No description provided for @creationCreatedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Outfit créé !'**
  String get creationCreatedSnack;

  /// No description provided for @creationLayersHint.
  ///
  /// In fr, this message translates to:
  /// **'Tu peux ajouter plusieurs pièces — l\'ordre suit celui de la liste (la première est la plus près du corps).'**
  String get creationLayersHint;

  /// No description provided for @creationNameRequiredSnack.
  ///
  /// In fr, this message translates to:
  /// **'Donne un nom à ton outfit.'**
  String get creationNameRequiredSnack;

  /// No description provided for @creationNewLookTitle.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau look'**
  String get creationNewLookTitle;

  /// No description provided for @creationNoGarmentInCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun vêtement dans cette catégorie'**
  String get creationNoGarmentInCategory;

  /// No description provided for @creationOutfitName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de l\'outfit'**
  String get creationOutfitName;

  /// No description provided for @creationPhotoRequired.
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire pour créer un look'**
  String get creationPhotoRequired;

  /// No description provided for @creationPieceAlreadyListed.
  ///
  /// In fr, this message translates to:
  /// **'Cette pièce est déjà dans la liste.'**
  String get creationPieceAlreadyListed;

  /// No description provided for @creationPiecesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Pièces du look'**
  String get creationPiecesTitle;

  /// No description provided for @creationSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Sauver'**
  String get creationSaveButton;

  /// No description provided for @creationSeasonsAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les saisons'**
  String get creationSeasonsAll;

  /// No description provided for @creationSeasonsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Saisons'**
  String get creationSeasonsLabel;

  /// No description provided for @creationSelectGarmentSnack.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne au moins un vêtement.'**
  String get creationSelectGarmentSnack;

  /// No description provided for @creationStepNamePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Nom & photo'**
  String get creationStepNamePhoto;

  /// No description provided for @creationStepPieces.
  ///
  /// In fr, this message translates to:
  /// **'Pièces'**
  String get creationStepPieces;

  /// No description provided for @creationStepWeather.
  ///
  /// In fr, this message translates to:
  /// **'Météo'**
  String get creationStepWeather;

  /// No description provided for @creationTorsoLayersSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Plusieurs couches : à gauche, la plus près du corps.'**
  String get creationTorsoLayersSubtitle;

  /// No description provided for @creationTorsoLayersTitle.
  ///
  /// In fr, this message translates to:
  /// **'Hauts (superposition)'**
  String get creationTorsoLayersTitle;

  /// No description provided for @creationUploadError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'upload'**
  String get creationUploadError;

  /// No description provided for @creationUploading.
  ///
  /// In fr, this message translates to:
  /// **'Upload en cours...'**
  String get creationUploading;

  /// No description provided for @creationWeatherAll.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les conditions'**
  String get creationWeatherAll;

  /// No description provided for @creationWeatherLabel.
  ///
  /// In fr, this message translates to:
  /// **'Temps'**
  String get creationWeatherLabel;

  /// No description provided for @creationWristAccessoriesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute autant d\'accessoires que tu veux.'**
  String get creationWristAccessoriesSubtitle;

  /// No description provided for @creationZoneFeet.
  ///
  /// In fr, this message translates to:
  /// **'Chaussures'**
  String get creationZoneFeet;

  /// No description provided for @creationZoneHead.
  ///
  /// In fr, this message translates to:
  /// **'Tête'**
  String get creationZoneHead;

  /// No description provided for @creationZoneJacket.
  ///
  /// In fr, this message translates to:
  /// **'Veste'**
  String get creationZoneJacket;

  /// No description provided for @creationZoneLegs.
  ///
  /// In fr, this message translates to:
  /// **'Bas'**
  String get creationZoneLegs;

  /// No description provided for @creationZoneTorso.
  ///
  /// In fr, this message translates to:
  /// **'Haut'**
  String get creationZoneTorso;

  /// No description provided for @creationZoneWrist.
  ///
  /// In fr, this message translates to:
  /// **'Accessoire'**
  String get creationZoneWrist;

  /// No description provided for @creatorActivationCode.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'activation'**
  String get creatorActivationCode;

  /// No description provided for @creatorActivationCodeInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'activation invalide.'**
  String get creatorActivationCodeInvalid;

  /// No description provided for @creatorBackToLogin.
  ///
  /// In fr, this message translates to:
  /// **'Retour à la connexion'**
  String get creatorBackToLogin;

  /// No description provided for @creatorBio.
  ///
  /// In fr, this message translates to:
  /// **'Bio'**
  String get creatorBio;

  /// No description provided for @creatorBrandName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la marque'**
  String get creatorBrandName;

  /// No description provided for @creatorCatalogEmptyHint.
  ///
  /// In fr, this message translates to:
  /// **'Crée une collection pour organiser ton catalogue.'**
  String get creatorCatalogEmptyHint;

  /// No description provided for @creatorCatalogTitle.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue marque'**
  String get creatorCatalogTitle;

  /// No description provided for @creatorCheckoutActivate.
  ///
  /// In fr, this message translates to:
  /// **'Activer mon espace marque'**
  String get creatorCheckoutActivate;

  /// No description provided for @creatorCheckoutEmailPasswordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Email et mot de passe (6 car. min.) requis.'**
  String get creatorCheckoutEmailPasswordRequired;

  /// No description provided for @creatorCheckoutSimulatedPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement simulé en développement. Saisis le code d\'activation pour activer ton espace.'**
  String get creatorCheckoutSimulatedPayment;

  /// No description provided for @creatorCheckoutTitle.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement marque'**
  String get creatorCheckoutTitle;

  /// No description provided for @creatorLandingDesc.
  ///
  /// In fr, this message translates to:
  /// **'Présente ton catalogue sur uniSaps : collections, vêtements et publications sponsorisées visibles dans le fil Inspiration des utilisateurs.'**
  String get creatorLandingDesc;

  /// No description provided for @creatorLandingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace marque'**
  String get creatorLandingTitle;

  /// No description provided for @creatorLogoLabel.
  ///
  /// In fr, this message translates to:
  /// **'Logo de la marque'**
  String get creatorLogoLabel;

  /// No description provided for @creatorNewCollectionTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle collection'**
  String get creatorNewCollectionTooltip;

  /// No description provided for @creatorNewPostPub.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau post pub'**
  String get creatorNewPostPub;

  /// No description provided for @creatorOnboardingBrandRequired.
  ///
  /// In fr, this message translates to:
  /// **'Nom de marque et identifiant requis.'**
  String get creatorOnboardingBrandRequired;

  /// No description provided for @creatorOnboardingFinish.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get creatorOnboardingFinish;

  /// No description provided for @creatorOnboardingLogoRequired.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute un logo pour ta marque.'**
  String get creatorOnboardingLogoRequired;

  /// No description provided for @creatorOnboardingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Profil marque'**
  String get creatorOnboardingTitle;

  /// No description provided for @creatorPersonalAccount.
  ///
  /// In fr, this message translates to:
  /// **'@compte perso uniSaps (optionnel)'**
  String get creatorPersonalAccount;

  /// No description provided for @creatorPostCollectionLabel.
  ///
  /// In fr, this message translates to:
  /// **'Collection'**
  String get creatorPostCollectionLabel;

  /// No description provided for @creatorPostCollectionsError.
  ///
  /// In fr, this message translates to:
  /// **'Collections : {error}'**
  String creatorPostCollectionsError(Object error);

  /// No description provided for @creatorPostFeedPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu feed'**
  String get creatorPostFeedPreview;

  /// No description provided for @creatorPostName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du post / look'**
  String get creatorPostName;

  /// No description provided for @creatorPostPubLabel.
  ///
  /// In fr, this message translates to:
  /// **'Post pub'**
  String get creatorPostPubLabel;

  /// No description provided for @creatorPostPublishFailed.
  ///
  /// In fr, this message translates to:
  /// **'Publication impossible.'**
  String get creatorPostPublishFailed;

  /// No description provided for @creatorPostPublishedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Post publicitaire publié.'**
  String get creatorPostPublishedSnack;

  /// No description provided for @creatorPostVisibleInFeed.
  ///
  /// In fr, this message translates to:
  /// **'Visible dans le feed (actif)'**
  String get creatorPostVisibleInFeed;

  /// No description provided for @creatorPostsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucun post pour l\'instant.'**
  String get creatorPostsEmpty;

  /// No description provided for @creatorPostsNoCollection.
  ///
  /// In fr, this message translates to:
  /// **'Sans collection'**
  String get creatorPostsNoCollection;

  /// No description provided for @creatorPostsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Posts publicitaires'**
  String get creatorPostsTitle;

  /// No description provided for @creatorProEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email professionnel'**
  String get creatorProEmail;

  /// No description provided for @creatorPublicId.
  ///
  /// In fr, this message translates to:
  /// **'@identifiant public'**
  String get creatorPublicId;

  /// No description provided for @creatorShopLinkCopied.
  ///
  /// In fr, this message translates to:
  /// **'Lien boutique copié'**
  String get creatorShopLinkCopied;

  /// No description provided for @creatorShopTitle.
  ///
  /// In fr, this message translates to:
  /// **'Boutique'**
  String get creatorShopTitle;

  /// No description provided for @creatorShopUrl.
  ///
  /// In fr, this message translates to:
  /// **'Lien boutique (URL)'**
  String get creatorShopUrl;

  /// No description provided for @creatorSubscriptionActive.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement actif'**
  String get creatorSubscriptionActive;

  /// No description provided for @creatorSubscriptionExpires.
  ///
  /// In fr, this message translates to:
  /// **'Expire le {date}'**
  String creatorSubscriptionExpires(Object date);

  /// No description provided for @creatorSubscriptionInactive.
  ///
  /// In fr, this message translates to:
  /// **'Abonnement inactif'**
  String get creatorSubscriptionInactive;

  /// No description provided for @creatorSubscriptionMonthlyPrice.
  ///
  /// In fr, this message translates to:
  /// **'29 \$ / mois'**
  String get creatorSubscriptionMonthlyPrice;

  /// No description provided for @creatorSubscriptionRate.
  ///
  /// In fr, this message translates to:
  /// **'Tarif : {price}'**
  String creatorSubscriptionRate(Object price);

  /// No description provided for @creatorTabGarments.
  ///
  /// In fr, this message translates to:
  /// **'Vêtements'**
  String get creatorTabGarments;

  /// No description provided for @creatorTabPosts.
  ///
  /// In fr, this message translates to:
  /// **'Posts'**
  String get creatorTabPosts;

  /// No description provided for @creatorTabProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get creatorTabProfile;

  /// No description provided for @creatorViewPersonalProfile.
  ///
  /// In fr, this message translates to:
  /// **'Voir mon profil perso'**
  String get creatorViewPersonalProfile;

  /// No description provided for @deleteAccountConfirmButton.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement'**
  String get deleteAccountConfirmButton;

  /// No description provided for @deleteAccountConfirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirme avec ton mot de passe :'**
  String get deleteAccountConfirmPassword;

  /// No description provided for @deleteAccountError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la suppression.'**
  String get deleteAccountError;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountWarning.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible. Toutes tes données seront supprimées définitivement.'**
  String get deleteAccountWarning;

  /// No description provided for @dressingAddFirstGarment.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ton premier vêtement !'**
  String get dressingAddFirstGarment;

  /// No description provided for @dressingAddGarment.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un vêtement'**
  String get dressingAddGarment;

  /// No description provided for @dressingAddShort.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get dressingAddShort;

  /// No description provided for @dressingEmptyDesc.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ta première pièce pour commencer.'**
  String get dressingEmptyDesc;

  /// No description provided for @dressingEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton dressing est vide'**
  String get dressingEmptyTitle;

  /// No description provided for @dressingFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get dressingFilterAll;

  /// No description provided for @dressingFilterBrand.
  ///
  /// In fr, this message translates to:
  /// **'— Marque'**
  String get dressingFilterBrand;

  /// No description provided for @dressingFilterColor.
  ///
  /// In fr, this message translates to:
  /// **'— Couleur'**
  String get dressingFilterColor;

  /// No description provided for @dressingMyWardrobe.
  ///
  /// In fr, this message translates to:
  /// **'Mon Dressing'**
  String get dressingMyWardrobe;

  /// No description provided for @dressingNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get dressingNameHint;

  /// No description provided for @dressingNewGarment.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau vêtement'**
  String get dressingNewGarment;

  /// No description provided for @dressingNoGarments.
  ///
  /// In fr, this message translates to:
  /// **'Aucun vêtement'**
  String get dressingNoGarments;

  /// No description provided for @dressingNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get dressingNoResults;

  /// No description provided for @dressingTryOtherFilters.
  ///
  /// In fr, this message translates to:
  /// **'Essaie un autre nom, marque ou couleur.'**
  String get dressingTryOtherFilters;

  /// No description provided for @emptyFeedExploreEmptySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Reviens plus tard pour découvrir de nouveaux looks.'**
  String get emptyFeedExploreEmptySubtitle;

  /// No description provided for @emptyFeedExploreEmptyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun post à explorer'**
  String get emptyFeedExploreEmptyTitle;

  /// No description provided for @emptyFeedExploreTitle.
  ///
  /// In fr, this message translates to:
  /// **'Explore le feed'**
  String get emptyFeedExploreTitle;

  /// No description provided for @emptyFeedFriendsNoFriendsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherche des utilisateurs pour les ajouter !'**
  String get emptyFeedFriendsNoFriendsSubtitle;

  /// No description provided for @emptyFeedFriendsNoFriendsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ami pour le moment'**
  String get emptyFeedFriendsNoFriendsTitle;

  /// No description provided for @emptyFeedFriendsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun post d\'amis'**
  String get emptyFeedFriendsTitle;

  /// No description provided for @emptyFeedFriendsTodaySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Reviens demain ou invite tes amis à publier.'**
  String get emptyFeedFriendsTodaySubtitle;

  /// No description provided for @emptyFeedFriendsTodayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun post de tes amis aujourd\'hui'**
  String get emptyFeedFriendsTodayTitle;

  /// No description provided for @friendRequestPending.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande en attente'**
  String get friendRequestPending;

  /// No description provided for @friendWantsToBe.
  ///
  /// In fr, this message translates to:
  /// **'Veut être ton ami'**
  String get friendWantsToBe;

  /// No description provided for @garmentAccessDenied.
  ///
  /// In fr, this message translates to:
  /// **'Accès refusé par le serveur. Si tu viens de te connecter, réessaie dans quelques secondes ; sinon préviens le support.'**
  String get garmentAccessDenied;

  /// No description provided for @garmentAddMorePhotos.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter d\'autres photos'**
  String get garmentAddMorePhotos;

  /// No description provided for @garmentAddPhotoCaption.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une photo'**
  String get garmentAddPhotoCaption;

  /// No description provided for @garmentAddPhotosTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une ou plusieurs photos'**
  String get garmentAddPhotosTitle;

  /// No description provided for @garmentAddToDressing.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au dressing'**
  String get garmentAddToDressing;

  /// No description provided for @garmentAddedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Vêtement ajouté !'**
  String get garmentAddedSnack;

  /// No description provided for @garmentAiAnalyzingImages.
  ///
  /// In fr, this message translates to:
  /// **'Analyse des images par l\'IA…'**
  String get garmentAiAnalyzingImages;

  /// No description provided for @garmentAiDescribeFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA n\'a pas pu décrire cette photo (service saturé ou image peu lisible). Tu peux remplir les champs manuellement ou réessayer avec une autre photo.'**
  String get garmentAiDescribeFailed;

  /// No description provided for @garmentAiSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Une seule analyse par ajout : la première photo (couleurs, catégorie, etc.).'**
  String get garmentAiSubtitle;

  /// No description provided for @garmentAiUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Analyse IA indisponible. Vérifie ta connexion et réessaie dans un instant.'**
  String get garmentAiUnavailable;

  /// No description provided for @garmentAnalyzing.
  ///
  /// In fr, this message translates to:
  /// **'Analyse IA en cours…'**
  String get garmentAnalyzing;

  /// No description provided for @garmentBrandHint.
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get garmentBrandHint;

  /// No description provided for @garmentBrandNoneFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune marque trouvée'**
  String get garmentBrandNoneFound;

  /// No description provided for @garmentBrandTapAgainToFilter.
  ///
  /// In fr, this message translates to:
  /// **'Appuie à nouveau pour filtrer…'**
  String get garmentBrandTapAgainToFilter;

  /// No description provided for @garmentCategoryLabel.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get garmentCategoryLabel;

  /// No description provided for @garmentCategoryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get garmentCategoryTitle;

  /// No description provided for @garmentChooseCollection.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une collection'**
  String get garmentChooseCollection;

  /// No description provided for @garmentCollectionCreateFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de créer la collection.'**
  String get garmentCollectionCreateFailed;

  /// No description provided for @garmentCollectionDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Suppression impossible.'**
  String get garmentCollectionDeleteFailed;

  /// No description provided for @garmentCollectionDeleteOnly.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » sera supprimée.'**
  String garmentCollectionDeleteOnly(Object name);

  /// No description provided for @garmentCollectionDeleteWithPiece.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » et sa pièce seront supprimées définitivement.'**
  String garmentCollectionDeleteWithPiece(Object name);

  /// No description provided for @garmentCollectionDeleteWithPieces.
  ///
  /// In fr, this message translates to:
  /// **'« {name} » et ses {count} pièces seront supprimées définitivement.'**
  String garmentCollectionDeleteWithPieces(Object count, Object name);

  /// No description provided for @garmentCollectionDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Collection supprimée.'**
  String get garmentCollectionDeleted;

  /// No description provided for @garmentCollectionEndDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de fin'**
  String get garmentCollectionEndDate;

  /// No description provided for @garmentCollectionExisting.
  ///
  /// In fr, this message translates to:
  /// **'Existante'**
  String get garmentCollectionExisting;

  /// No description provided for @garmentCollectionNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la collection'**
  String get garmentCollectionNameHint;

  /// No description provided for @garmentCollectionNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom de la collection est obligatoire.'**
  String get garmentCollectionNameRequired;

  /// No description provided for @garmentCollectionNameRequiredSnack.
  ///
  /// In fr, this message translates to:
  /// **'Indique un nom de collection.'**
  String get garmentCollectionNameRequiredSnack;

  /// No description provided for @garmentCollectionNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle collection'**
  String get garmentCollectionNew;

  /// No description provided for @garmentCollectionSection.
  ///
  /// In fr, this message translates to:
  /// **'Collection'**
  String get garmentCollectionSection;

  /// No description provided for @garmentCollectionStartDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de début'**
  String get garmentCollectionStartDate;

  /// No description provided for @garmentCollectionsErrorPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Collections : '**
  String get garmentCollectionsErrorPrefix;

  /// No description provided for @garmentColorHint.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get garmentColorHint;

  /// No description provided for @garmentColorMaxReached.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 3 couleurs atteint'**
  String get garmentColorMaxReached;

  /// No description provided for @garmentColorNoneFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune couleur trouvée'**
  String get garmentColorNoneFound;

  /// No description provided for @garmentColorSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher une couleur…'**
  String get garmentColorSearchHint;

  /// No description provided for @garmentColorTapAgainToFilter.
  ///
  /// In fr, this message translates to:
  /// **'Taper à nouveau pour filtrer'**
  String get garmentColorTapAgainToFilter;

  /// No description provided for @garmentColorsLabel.
  ///
  /// In fr, this message translates to:
  /// **'Couleurs'**
  String get garmentColorsLabel;

  /// No description provided for @garmentCreateCollectionFirst.
  ///
  /// In fr, this message translates to:
  /// **'Crée d\'abord une collection depuis ton catalogue marque.'**
  String get garmentCreateCollectionFirst;

  /// No description provided for @garmentCreatorPseudoMissing.
  ///
  /// In fr, this message translates to:
  /// **'Ton pseudo (@identifiant) est introuvable. Complète ton profil créateur.'**
  String get garmentCreatorPseudoMissing;

  /// No description provided for @garmentDateEndHint.
  ///
  /// In fr, this message translates to:
  /// **'Fin (AAAA-MM-JJ)'**
  String get garmentDateEndHint;

  /// No description provided for @garmentDateStartHint.
  ///
  /// In fr, this message translates to:
  /// **'Début (AAAA-MM-JJ)'**
  String get garmentDateStartHint;

  /// No description provided for @garmentDeleteCollectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la collection ?'**
  String get garmentDeleteCollectionTitle;

  /// No description provided for @garmentDeleteConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer ce vêtement ?'**
  String get garmentDeleteConfirmTitle;

  /// No description provided for @garmentEditButton.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get garmentEditButton;

  /// No description provided for @garmentEditTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le vêtement'**
  String get garmentEditTitle;

  /// No description provided for @garmentFirebaseConfigMissing.
  ///
  /// In fr, this message translates to:
  /// **'Configuration Firebase manquante. Vérifie le fichier serviceAccountKey.json dans backend/'**
  String get garmentFirebaseConfigMissing;

  /// No description provided for @garmentGalleryMultiple.
  ///
  /// In fr, this message translates to:
  /// **'Galerie - plusieurs photos'**
  String get garmentGalleryMultiple;

  /// No description provided for @garmentImageNotRecognizedBody.
  ///
  /// In fr, this message translates to:
  /// **'L\'IA n\'a pas reconnu de vêtement, chaussure ou accessoire sur cette photo. Choisis une autre image plus claire montrant la pièce que tu veux ajouter.'**
  String get garmentImageNotRecognizedBody;

  /// No description provided for @garmentImageNotRecognizedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Image non reconnue'**
  String get garmentImageNotRecognizedTitle;

  /// No description provided for @garmentMaxThreeColors.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 3 couleurs autorisées'**
  String get garmentMaxThreeColors;

  /// No description provided for @garmentNameDescHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom / description'**
  String get garmentNameDescHint;

  /// No description provided for @garmentNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom est obligatoire.'**
  String get garmentNameRequired;

  /// No description provided for @garmentNoItemsInCategory.
  ///
  /// In fr, this message translates to:
  /// **'Aucun vêtement dans cette catégorie'**
  String get garmentNoItemsInCategory;

  /// No description provided for @garmentPrefillAi.
  ///
  /// In fr, this message translates to:
  /// **'Pré-remplir avec l\'IA'**
  String get garmentPrefillAi;

  /// No description provided for @garmentRemoveBackground.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'arrière-plan'**
  String get garmentRemoveBackground;

  /// No description provided for @garmentRemoveBackgroundHint.
  ///
  /// In fr, this message translates to:
  /// **'Utilise l\'IA pour isoler le vêtement. Décoche si tu veux garder le fond.'**
  String get garmentRemoveBackgroundHint;

  /// No description provided for @garmentSaveButton.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get garmentSaveButton;

  /// No description provided for @garmentSaveError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'enregistrement.'**
  String get garmentSaveError;

  /// No description provided for @garmentSaveGarment.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer le vêtement'**
  String get garmentSaveGarment;

  /// No description provided for @garmentSaving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement…'**
  String get garmentSaving;

  /// No description provided for @garmentSelectCollection.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionne une collection.'**
  String get garmentSelectCollection;

  /// No description provided for @garmentServerContactFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de contacter le serveur. Réessaie dans un instant.'**
  String get garmentServerContactFailed;

  /// No description provided for @garmentServerUnreachable.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur est inaccessible. Réessaie dans un instant.'**
  String get garmentServerUnreachable;

  /// No description provided for @garmentSessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée ou jeton invalide. Déconnecte-toi, reconnecte-toi, puis réessaie.'**
  String get garmentSessionExpired;

  /// No description provided for @garmentStoragePermissions.
  ///
  /// In fr, this message translates to:
  /// **'Le serveur n\'a pas les droits pour enregistrer l\'image sur Firebase Storage. Dans Google Cloud Console → IAM, attribue au compte de service du backend le rôle Storage Admin ou Storage Object Creator.'**
  String get garmentStoragePermissions;

  /// No description provided for @garmentTakePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une photo'**
  String get garmentTakePhoto;

  /// No description provided for @garmentUpdateGarment.
  ///
  /// In fr, this message translates to:
  /// **'Mettre à jour'**
  String get garmentUpdateGarment;

  /// No description provided for @garmentUpdatedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Vêtement modifié !'**
  String get garmentUpdatedSnack;

  /// No description provided for @garmentUploadTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Le traitement d\'une image prend trop de temps. Vérifie que le backend est démarré et patiente.'**
  String get garmentUploadTimeout;

  /// No description provided for @inspoAddPhotoToPublish.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute au moins une photo à ton outfit pour publier.'**
  String get inspoAddPhotoToPublish;

  /// No description provided for @inspoAlreadyPostedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Tu as déjà publié ton outfit aujourd\'hui !'**
  String get inspoAlreadyPostedSnack;

  /// No description provided for @inspoCaption.
  ///
  /// In fr, this message translates to:
  /// **'Légende...'**
  String get inspoCaption;

  /// No description provided for @inspoCaptionOptional.
  ///
  /// In fr, this message translates to:
  /// **'Légende (optionnel)...'**
  String get inspoCaptionOptional;

  /// No description provided for @inspoCaptionVisibleHint.
  ///
  /// In fr, this message translates to:
  /// **'Texte visible sous la photo'**
  String get inspoCaptionVisibleHint;

  /// No description provided for @inspoChipYou.
  ///
  /// In fr, this message translates to:
  /// **'Toi'**
  String get inspoChipYou;

  /// No description provided for @inspoChooseOutfitFirst.
  ///
  /// In fr, this message translates to:
  /// **'Choisis d\'abord ton outfit du jour'**
  String get inspoChooseOutfitFirst;

  /// No description provided for @inspoDefaultOutfitName.
  ///
  /// In fr, this message translates to:
  /// **'Mon outfit du jour'**
  String get inspoDefaultOutfitName;

  /// No description provided for @inspoDeletePostConfirmBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette publication sera retirée du fil.'**
  String get inspoDeletePostConfirmBody;

  /// No description provided for @inspoDeletePostConfirmTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le post ?'**
  String get inspoDeletePostConfirmTitle;

  /// No description provided for @inspoDeletePostIrreversible.
  ///
  /// In fr, this message translates to:
  /// **'Irréversible'**
  String get inspoDeletePostIrreversible;

  /// No description provided for @inspoDeletePostTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le post'**
  String get inspoDeletePostTitle;

  /// No description provided for @inspoDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get inspoDetails;

  /// No description provided for @inspoEditCaptionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la légende'**
  String get inspoEditCaptionTitle;

  /// No description provided for @inspoEmptyExplore.
  ///
  /// In fr, this message translates to:
  /// **'Aucun post pour le moment.'**
  String get inspoEmptyExplore;

  /// No description provided for @inspoEmptyFriends.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute des amis pour voir leurs looks ici.'**
  String get inspoEmptyFriends;

  /// No description provided for @inspoExplore.
  ///
  /// In fr, this message translates to:
  /// **'Explorer'**
  String get inspoExplore;

  /// No description provided for @inspoFeedEndSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Reviens demain pour de nouveaux looks.'**
  String get inspoFeedEndSubtitle;

  /// No description provided for @inspoFeedEndTitle.
  ///
  /// In fr, this message translates to:
  /// **'Fin des posts du jour'**
  String get inspoFeedEndTitle;

  /// No description provided for @inspoFeedExplore.
  ///
  /// In fr, this message translates to:
  /// **'Explorer'**
  String get inspoFeedExplore;

  /// No description provided for @inspoFeedFriends.
  ///
  /// In fr, this message translates to:
  /// **'Amis'**
  String get inspoFeedFriends;

  /// No description provided for @inspoFeedSemanticsPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Fil Inspiration : '**
  String get inspoFeedSemanticsPrefix;

  /// No description provided for @inspoFindFriends.
  ///
  /// In fr, this message translates to:
  /// **'Trouver des amis'**
  String get inspoFindFriends;

  /// No description provided for @inspoFitPieces.
  ///
  /// In fr, this message translates to:
  /// **'Pièces du fit'**
  String get inspoFitPieces;

  /// No description provided for @inspoFriendRequestSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée à '**
  String get inspoFriendRequestSent;

  /// No description provided for @inspoFriendRequestSentExclaim.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée à @{username} !'**
  String inspoFriendRequestSentExclaim(Object username);

  /// No description provided for @inspoFriends.
  ///
  /// In fr, this message translates to:
  /// **'Amis'**
  String get inspoFriends;

  /// No description provided for @inspoOptions.
  ///
  /// In fr, this message translates to:
  /// **'Options'**
  String get inspoOptions;

  /// No description provided for @inspoOutfitNoLongerExists.
  ///
  /// In fr, this message translates to:
  /// **'Cet outfit n\'existe plus. Choisis un outfit du jour.'**
  String get inspoOutfitNoLongerExists;

  /// No description provided for @inspoPostDeleteFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer le post.'**
  String get inspoPostDeleteFailed;

  /// No description provided for @inspoPostDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Post supprimé.'**
  String get inspoPostDeleted;

  /// No description provided for @inspoPreparePostError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la préparation du post.'**
  String get inspoPreparePostError;

  /// No description provided for @inspoPublish.
  ///
  /// In fr, this message translates to:
  /// **'Publier'**
  String get inspoPublish;

  /// No description provided for @inspoPublishFailed.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la publication.'**
  String get inspoPublishFailed;

  /// No description provided for @inspoPublishToday.
  ///
  /// In fr, this message translates to:
  /// **'Publier mon look du jour'**
  String get inspoPublishToday;

  /// No description provided for @inspoPublishTodayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Publier l\'outfit du jour'**
  String get inspoPublishTodayTitle;

  /// No description provided for @inspoPublishedSnack.
  ///
  /// In fr, this message translates to:
  /// **'Outfit publié !'**
  String get inspoPublishedSnack;

  /// No description provided for @inspoRequestsSection.
  ///
  /// In fr, this message translates to:
  /// **'Demandes'**
  String get inspoRequestsSection;

  /// No description provided for @inspoScrollHint.
  ///
  /// In fr, this message translates to:
  /// **'Fais défiler pour parcourir les looks'**
  String get inspoScrollHint;

  /// No description provided for @inspoSearchNoResults.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get inspoSearchNoResults;

  /// No description provided for @inspoSearchTypeHint.
  ///
  /// In fr, this message translates to:
  /// **'Tape un nom pour chercher'**
  String get inspoSearchTypeHint;

  /// No description provided for @inspoSearchUser.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un utilisateur...'**
  String get inspoSearchUser;

  /// No description provided for @inspoSponsored.
  ///
  /// In fr, this message translates to:
  /// **'Sponsorisé'**
  String get inspoSponsored;

  /// No description provided for @languageContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get languageContinue;

  /// No description provided for @languageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @languageSelectionSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Tu pourras la modifier plus tard dans ton compte.'**
  String get languageSelectionSubtitle;

  /// No description provided for @languageSelectionTitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis ta langue'**
  String get languageSelectionTitle;

  /// No description provided for @lockTabAddGarment.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute un vêtement à ton dressing pour débloquer cette section'**
  String get lockTabAddGarment;

  /// No description provided for @lockTabCreateOutfit.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton premier outfit pour débloquer cette section'**
  String get lockTabCreateOutfit;

  /// No description provided for @navDressing.
  ///
  /// In fr, this message translates to:
  /// **'Dressing'**
  String get navDressing;

  /// No description provided for @navInspiration.
  ///
  /// In fr, this message translates to:
  /// **'Inspiration'**
  String get navInspiration;

  /// No description provided for @navOutfits.
  ///
  /// In fr, this message translates to:
  /// **'Outfits'**
  String get navOutfits;

  /// No description provided for @navProfile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get navProfile;

  /// No description provided for @outfitsAddFit.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un fit'**
  String get outfitsAddFit;

  /// No description provided for @outfitsAddToLibrary.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un fit à la bibliothèque'**
  String get outfitsAddToLibrary;

  /// No description provided for @outfitsAiSuggestionName.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion IA'**
  String get outfitsAiSuggestionName;

  /// No description provided for @outfitsAiSuggestionsShort.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions IA'**
  String get outfitsAiSuggestionsShort;

  /// No description provided for @outfitsChangePhoto.
  ///
  /// In fr, this message translates to:
  /// **'Changer'**
  String get outfitsChangePhoto;

  /// No description provided for @outfitsChooseThisLook.
  ///
  /// In fr, this message translates to:
  /// **'Choisir ce look'**
  String get outfitsChooseThisLook;

  /// No description provided for @outfitsChooseToday.
  ///
  /// In fr, this message translates to:
  /// **'Choisir pour aujourd\'hui'**
  String get outfitsChooseToday;

  /// No description provided for @outfitsCreateTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Créer une tenue'**
  String get outfitsCreateTooltip;

  /// No description provided for @outfitsDayPhoto.
  ///
  /// In fr, this message translates to:
  /// **'Photo du jour'**
  String get outfitsDayPhoto;

  /// No description provided for @outfitsDeleteOutfitBody.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible.'**
  String get outfitsDeleteOutfitBody;

  /// No description provided for @outfitsDeleteOutfitTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'outfit ?'**
  String get outfitsDeleteOutfitTitle;

  /// No description provided for @outfitsDeleteTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cet outfit'**
  String get outfitsDeleteTooltip;

  /// No description provided for @outfitsEmptyLibrarySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton premier look en ajoutant\nune photo et tes vêtements'**
  String get outfitsEmptyLibrarySubtitle;

  /// No description provided for @outfitsEmptyLibraryTitle.
  ///
  /// In fr, this message translates to:
  /// **'Aucun outfit'**
  String get outfitsEmptyLibraryTitle;

  /// No description provided for @outfitsForToday.
  ///
  /// In fr, this message translates to:
  /// **'Pour aujourd\'hui'**
  String get outfitsForToday;

  /// No description provided for @outfitsGenerateError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de la génération'**
  String get outfitsGenerateError;

  /// No description provided for @outfitsGenerateSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Générer des suggestions'**
  String get outfitsGenerateSuggestions;

  /// No description provided for @outfitsGenerating.
  ///
  /// In fr, this message translates to:
  /// **'Génération…'**
  String get outfitsGenerating;

  /// No description provided for @outfitsLookLabel.
  ///
  /// In fr, this message translates to:
  /// **'Look '**
  String get outfitsLookLabel;

  /// No description provided for @outfitsModeBiblio.
  ///
  /// In fr, this message translates to:
  /// **'Biblio'**
  String get outfitsModeBiblio;

  /// No description provided for @outfitsModeSwipe.
  ///
  /// In fr, this message translates to:
  /// **'Swipe'**
  String get outfitsModeSwipe;

  /// No description provided for @outfitsMorningAi.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions UniSaps+'**
  String get outfitsMorningAi;

  /// No description provided for @outfitsMorningAiDiscover.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir les suggestions UniSaps+'**
  String get outfitsMorningAiDiscover;

  /// No description provided for @outfitsMorningBiblio.
  ///
  /// In fr, this message translates to:
  /// **'Ma bibliothèque'**
  String get outfitsMorningBiblio;

  /// No description provided for @outfitsMorningSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Choisis comment parcourir tes tenues.'**
  String get outfitsMorningSubtitle;

  /// No description provided for @outfitsMorningSwipe.
  ///
  /// In fr, this message translates to:
  /// **'Swiper'**
  String get outfitsMorningSwipe;

  /// No description provided for @outfitsMorningTitle.
  ///
  /// In fr, this message translates to:
  /// **'Quel look pour aujourd\'hui ?'**
  String get outfitsMorningTitle;

  /// No description provided for @outfitsMyOutfitsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Mes Outfits'**
  String get outfitsMyOutfitsTitle;

  /// No description provided for @outfitsNoPiecesForSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pièce reconnue dans ton dressing pour cette suggestion.'**
  String get outfitsNoPiecesForSuggestion;

  /// No description provided for @outfitsPiecePlural.
  ///
  /// In fr, this message translates to:
  /// **' pièces'**
  String get outfitsPiecePlural;

  /// No description provided for @outfitsPieceSingular.
  ///
  /// In fr, this message translates to:
  /// **' pièce'**
  String get outfitsPieceSingular;

  /// No description provided for @outfitsPrecisionHint.
  ///
  /// In fr, this message translates to:
  /// **'Précision (facultatif): ex. dîner chic, concert…'**
  String get outfitsPrecisionHint;

  /// No description provided for @outfitsPremiumRequiredAi.
  ///
  /// In fr, this message translates to:
  /// **'UniSaps+ requis pour les suggestions IA'**
  String get outfitsPremiumRequiredAi;

  /// No description provided for @outfitsRestart.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer'**
  String get outfitsRestart;

  /// No description provided for @outfitsStreakDaysSuffix.
  ///
  /// In fr, this message translates to:
  /// **' jours'**
  String get outfitsStreakDaysSuffix;

  /// No description provided for @outfitsStreakDialogBarrier.
  ///
  /// In fr, this message translates to:
  /// **'Célébration de streak'**
  String get outfitsStreakDialogBarrier;

  /// No description provided for @outfitsStreakEncourage.
  ///
  /// In fr, this message translates to:
  /// **'Tu gardes la flamme, continue !'**
  String get outfitsStreakEncourage;

  /// No description provided for @outfitsStreakLine.
  ///
  /// In fr, this message translates to:
  /// **'Streak de '**
  String get outfitsStreakLine;

  /// No description provided for @outfitsSwipeEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Oups… Plus aucun choix d\'outfits,\nOn recommence ?'**
  String get outfitsSwipeEmpty;

  /// No description provided for @outfitsTapForDetails.
  ///
  /// In fr, this message translates to:
  /// **'Tap pour voir les détails'**
  String get outfitsTapForDetails;

  /// No description provided for @outfitsTodayBadge.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get outfitsTodayBadge;

  /// No description provided for @outfitsTodayTitle.
  ///
  /// In fr, this message translates to:
  /// **'Outfit du jour'**
  String get outfitsTodayTitle;

  /// No description provided for @outfitsWeatherTodayPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Météo du jour, '**
  String get outfitsWeatherTodayPrefix;

  /// No description provided for @pickerCamera.
  ///
  /// In fr, this message translates to:
  /// **'Appareil photo'**
  String get pickerCamera;

  /// No description provided for @pickerGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get pickerGallery;

  /// No description provided for @premiumDialogActivateHint.
  ///
  /// In fr, this message translates to:
  /// **'Active UniSaps+ depuis ton profil (onglet Compte).'**
  String get premiumDialogActivateHint;

  /// No description provided for @premiumDialogBenefit1.
  ///
  /// In fr, this message translates to:
  /// **'Analyse photo IA'**
  String get premiumDialogBenefit1;

  /// No description provided for @premiumDialogBenefit1Full.
  ///
  /// In fr, this message translates to:
  /// **'Analyse IA de tes photos de vêtements'**
  String get premiumDialogBenefit1Full;

  /// No description provided for @premiumDialogBenefit2.
  ///
  /// In fr, this message translates to:
  /// **'3 suggestions / matin'**
  String get premiumDialogBenefit2;

  /// No description provided for @premiumDialogBenefit2Full.
  ///
  /// In fr, this message translates to:
  /// **'3 suggestions d\'outfits chaque matin'**
  String get premiumDialogBenefit2Full;

  /// No description provided for @premiumDialogBenefit3.
  ///
  /// In fr, this message translates to:
  /// **'Badge premium'**
  String get premiumDialogBenefit3;

  /// No description provided for @premiumDialogBenefit3Full.
  ///
  /// In fr, this message translates to:
  /// **'Badge premium sur ton profil'**
  String get premiumDialogBenefit3Full;

  /// No description provided for @premiumDialogCta.
  ///
  /// In fr, this message translates to:
  /// **'Voir UniSaps+'**
  String get premiumDialogCta;

  /// No description provided for @premiumDialogPriceLifetime.
  ///
  /// In fr, this message translates to:
  /// **'5 € à vie'**
  String get premiumDialogPriceLifetime;

  /// No description provided for @premiumDialogPriceLifetimeFull.
  ///
  /// In fr, this message translates to:
  /// **'ou 5 € à vie (achat unique)'**
  String get premiumDialogPriceLifetimeFull;

  /// No description provided for @premiumDialogPriceMonthly.
  ///
  /// In fr, this message translates to:
  /// **'1 €/mois'**
  String get premiumDialogPriceMonthly;

  /// No description provided for @premiumDialogPriceMonthlyFull.
  ///
  /// In fr, this message translates to:
  /// **'1 € / mois'**
  String get premiumDialogPriceMonthlyFull;

  /// No description provided for @premiumDialogTitle.
  ///
  /// In fr, this message translates to:
  /// **'UniSaps+'**
  String get premiumDialogTitle;

  /// No description provided for @premiumDialogTitleFull.
  ///
  /// In fr, this message translates to:
  /// **'Passe en UniSaps+'**
  String get premiumDialogTitleFull;

  /// No description provided for @profileAccountPrivate.
  ///
  /// In fr, this message translates to:
  /// **'Privé'**
  String get profileAccountPrivate;

  /// No description provided for @profileAccountPublic.
  ///
  /// In fr, this message translates to:
  /// **'Public'**
  String get profileAccountPublic;

  /// No description provided for @profileActivateUniSaps.
  ///
  /// In fr, this message translates to:
  /// **'Activer UniSaps+'**
  String get profileActivateUniSaps;

  /// No description provided for @profileActivationCodeLabel.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'activation'**
  String get profileActivationCodeLabel;

  /// No description provided for @profileAddFriend.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un ami'**
  String get profileAddFriend;

  /// No description provided for @profileBestStreak.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur streak'**
  String get profileBestStreak;

  /// No description provided for @profileBestStreakLine.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur streak : '**
  String get profileBestStreakLine;

  /// No description provided for @profileDarkModeSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Confort visuel en faible luminosité'**
  String get profileDarkModeSubtitle;

  /// No description provided for @profileDays.
  ///
  /// In fr, this message translates to:
  /// **'jours'**
  String get profileDays;

  /// No description provided for @profileDefaultOutfitName.
  ///
  /// In fr, this message translates to:
  /// **'Outfit'**
  String get profileDefaultOutfitName;

  /// No description provided for @profileDeleteAccount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le compte'**
  String get profileDeleteAccount;

  /// No description provided for @profileDeleteIrreversible.
  ///
  /// In fr, this message translates to:
  /// **'Cette action est irréversible.'**
  String get profileDeleteIrreversible;

  /// No description provided for @profileDisplayName.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get profileDisplayName;

  /// No description provided for @profileEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileErrorPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Erreur : '**
  String get profileErrorPrefix;

  /// No description provided for @profileFriendLabel.
  ///
  /// In fr, this message translates to:
  /// **'ami'**
  String get profileFriendLabel;

  /// No description provided for @profileFriendRequestSnack.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle demande d\'ami'**
  String get profileFriendRequestSnack;

  /// No description provided for @profileFriendRequestsPending.
  ///
  /// In fr, this message translates to:
  /// **'demandes d\'amis en attente'**
  String get profileFriendRequestsPending;

  /// No description provided for @profileFriendsLabel.
  ///
  /// In fr, this message translates to:
  /// **'amis'**
  String get profileFriendsLabel;

  /// No description provided for @profileFriendsSection.
  ///
  /// In fr, this message translates to:
  /// **'Amis'**
  String get profileFriendsSection;

  /// No description provided for @profileIncorrectCode.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect.'**
  String get profileIncorrectCode;

  /// No description provided for @profileIncorrectPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe incorrect.'**
  String get profileIncorrectPassword;

  /// No description provided for @profileLastWornPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Dernier port : '**
  String get profileLastWornPrefix;

  /// No description provided for @profileLogOut.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get profileLogOut;

  /// No description provided for @profileMemberSince.
  ///
  /// In fr, this message translates to:
  /// **'Membre depuis'**
  String get profileMemberSince;

  /// No description provided for @profileMemoryPhotoHint.
  ///
  /// In fr, this message translates to:
  /// **'Photo prise lors du choix de l\'outfit du jour.'**
  String get profileMemoryPhotoHint;

  /// No description provided for @profileMostWornTitle.
  ///
  /// In fr, this message translates to:
  /// **'Les plus portes'**
  String get profileMostWornTitle;

  /// No description provided for @profileMyFriendsPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Mes amis'**
  String get profileMyFriendsPrefix;

  /// No description provided for @profileNoFriendsYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ami pour le moment'**
  String get profileNoFriendsYet;

  /// No description provided for @profileNoGarmentsLinked.
  ///
  /// In fr, this message translates to:
  /// **'Aucun vêtement associé.'**
  String get profileNoGarmentsLinked;

  /// No description provided for @profileNoMemoriesYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun souvenir pour l\'instant'**
  String get profileNoMemoriesYet;

  /// No description provided for @profileNoOutfits.
  ///
  /// In fr, this message translates to:
  /// **'Aucun outfit'**
  String get profileNoOutfits;

  /// No description provided for @profileOneFriendRequestPending.
  ///
  /// In fr, this message translates to:
  /// **'Une demande d\'ami en attente'**
  String get profileOneFriendRequestPending;

  /// No description provided for @profilePieceNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Pièce introuvable'**
  String get profilePieceNotFound;

  /// No description provided for @profilePremiumActivatedSnack.
  ///
  /// In fr, this message translates to:
  /// **'UniSaps+ activé ! Profite des fonctionnalités IA.'**
  String get profilePremiumActivatedSnack;

  /// No description provided for @profilePremiumActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get profilePremiumActive;

  /// No description provided for @profilePremiumCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Entre ton code UniSaps+'**
  String get profilePremiumCodeHint;

  /// No description provided for @profilePremiumFree.
  ///
  /// In fr, this message translates to:
  /// **'Gratuit'**
  String get profilePremiumFree;

  /// No description provided for @profilePremiumTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Compte UniSaps+'**
  String get profilePremiumTooltip;

  /// No description provided for @profilePrivateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte privé'**
  String get profilePrivateAccount;

  /// No description provided for @profilePrivateEveryone.
  ///
  /// In fr, this message translates to:
  /// **'Tout le monde peut voir ton contenu'**
  String get profilePrivateEveryone;

  /// No description provided for @profilePrivateFriendsOnly.
  ///
  /// In fr, this message translates to:
  /// **'Seuls tes amis voient ton contenu'**
  String get profilePrivateFriendsOnly;

  /// No description provided for @profilePrivateTooltip.
  ///
  /// In fr, this message translates to:
  /// **'Profil privé'**
  String get profilePrivateTooltip;

  /// No description provided for @profileReceivedRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes reçues'**
  String get profileReceivedRequests;

  /// No description provided for @profileRemoveFriendAction.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get profileRemoveFriendAction;

  /// No description provided for @profileRemoveFriendBodyPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Retirer @'**
  String get profileRemoveFriendBodyPrefix;

  /// No description provided for @profileRemoveFriendBodySuffix.
  ///
  /// In fr, this message translates to:
  /// **' de ta liste d\'amis ?'**
  String get profileRemoveFriendBodySuffix;

  /// No description provided for @profileRemoveFriendTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retirer cet ami ?'**
  String get profileRemoveFriendTitle;

  /// No description provided for @profileScrollMore.
  ///
  /// In fr, this message translates to:
  /// **'Fais défiler'**
  String get profileScrollMore;

  /// No description provided for @profileSettingsSection.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get profileSettingsSection;

  /// No description provided for @profileStreakDaysSuffix.
  ///
  /// In fr, this message translates to:
  /// **' jours'**
  String get profileStreakDaysSuffix;

  /// No description provided for @profileStreakShort.
  ///
  /// In fr, this message translates to:
  /// **'j. série'**
  String get profileStreakShort;

  /// No description provided for @profileTabAccount.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get profileTabAccount;

  /// No description provided for @profileTabGallery.
  ///
  /// In fr, this message translates to:
  /// **'Galerie'**
  String get profileTabGallery;

  /// No description provided for @profileTabMemories.
  ///
  /// In fr, this message translates to:
  /// **'Souvenirs'**
  String get profileTabMemories;

  /// No description provided for @profileTabOutfits.
  ///
  /// In fr, this message translates to:
  /// **'Tenues'**
  String get profileTabOutfits;

  /// No description provided for @profileTabStats.
  ///
  /// In fr, this message translates to:
  /// **'Stats'**
  String get profileTabStats;

  /// No description provided for @profileTimesSuffix.
  ///
  /// In fr, this message translates to:
  /// **'×'**
  String get profileTimesSuffix;

  /// No description provided for @profileUsername.
  ///
  /// In fr, this message translates to:
  /// **'Pseudo'**
  String get profileUsername;

  /// No description provided for @profileViewProfile.
  ///
  /// In fr, this message translates to:
  /// **'Voir le profil'**
  String get profileViewProfile;

  /// No description provided for @profileWornPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Porté '**
  String get profileWornPrefix;

  /// No description provided for @requestsTab.
  ///
  /// In fr, this message translates to:
  /// **'Demandes'**
  String get requestsTab;

  /// No description provided for @searchFriendsOfFriends.
  ///
  /// In fr, this message translates to:
  /// **'Amis d\'amis et profils similaires'**
  String get searchFriendsOfFriends;

  /// No description provided for @searchFriendsSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions d\'amis'**
  String get searchFriendsSuggestions;

  /// No description provided for @searchMutualFriendSingular.
  ///
  /// In fr, this message translates to:
  /// **'ami en commun'**
  String get searchMutualFriendSingular;

  /// No description provided for @searchMutualFriends.
  ///
  /// In fr, this message translates to:
  /// **'amis en commun'**
  String get searchMutualFriends;

  /// No description provided for @searchMutualFriendsPlural.
  ///
  /// In fr, this message translates to:
  /// **'amis en commun'**
  String get searchMutualFriendsPlural;

  /// No description provided for @searchNoResultsShort.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat'**
  String get searchNoResultsShort;

  /// No description provided for @searchNoSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Aucune suggestion pour le moment'**
  String get searchNoSuggestions;

  /// No description provided for @searchRandomSuggestion.
  ///
  /// In fr, this message translates to:
  /// **'Suggestion aléatoire'**
  String get searchRandomSuggestion;

  /// No description provided for @searchSuggestionsForYou.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions pour toi'**
  String get searchSuggestionsForYou;

  /// No description provided for @searchSuggestionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions'**
  String get searchSuggestionsTitle;

  /// No description provided for @searchTab.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get searchTab;

  /// No description provided for @searchTypePseudo.
  ///
  /// In fr, this message translates to:
  /// **'Tape un pseudo pour chercher'**
  String get searchTypePseudo;

  /// No description provided for @seasonAutumn.
  ///
  /// In fr, this message translates to:
  /// **'Automne'**
  String get seasonAutumn;

  /// No description provided for @seasonSpring.
  ///
  /// In fr, this message translates to:
  /// **'Printemps'**
  String get seasonSpring;

  /// No description provided for @seasonSummer.
  ///
  /// In fr, this message translates to:
  /// **'Été'**
  String get seasonSummer;

  /// No description provided for @seasonWinter.
  ///
  /// In fr, this message translates to:
  /// **'Hiver'**
  String get seasonWinter;

  /// No description provided for @settingsDarkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get settingsDarkMode;

  /// No description provided for @settingsLanguage.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageFrench.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get settingsLanguageFrench;

  /// No description provided for @signupCreatorAlreadyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get signupCreatorAlreadyAccount;

  /// No description provided for @signupCreatorBrandNextPage.
  ///
  /// In fr, this message translates to:
  /// **'Inscription marque sur la page suivante'**
  String get signupCreatorBrandNextPage;

  /// No description provided for @signupCreatorCard1Body.
  ///
  /// In fr, this message translates to:
  /// **'Les utilisateurs font défiler des cartes : looks, profils, créateurs. Ta marque apparaît dans ce flux — un swipe vers la droite, comme pour montrer son intérêt sur une tenue.'**
  String get signupCreatorCard1Body;

  /// No description provided for @signupCreatorCard1Title.
  ///
  /// In fr, this message translates to:
  /// **'Le même geste qu\'Inspiration'**
  String get signupCreatorCard1Title;

  /// No description provided for @signupCreatorCard2Body.
  ///
  /// In fr, this message translates to:
  /// **'Tu exposes tes pièces et tenues dans un espace dédié : ton dressing pro, séparé des comptes perso, toujours relié au reste de l\'app.'**
  String get signupCreatorCard2Body;

  /// No description provided for @signupCreatorCard2Title.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue & dressing marque'**
  String get signupCreatorCard2Title;

  /// No description provided for @signupCreatorCard3Body.
  ///
  /// In fr, this message translates to:
  /// **'Mets en avant une collection ou une pièce avec des posts sponsorisés : tu captes l\'attention au bon endroit, sans changer les habitudes des gens.'**
  String get signupCreatorCard3Body;

  /// No description provided for @signupCreatorCard3Title.
  ///
  /// In fr, this message translates to:
  /// **'Visibilité & publications'**
  String get signupCreatorCard3Title;

  /// No description provided for @signupCreatorCatalogOutfits.
  ///
  /// In fr, this message translates to:
  /// **'Tenues'**
  String get signupCreatorCatalogOutfits;

  /// No description provided for @signupCreatorCatalogPieces.
  ///
  /// In fr, this message translates to:
  /// **'Pièces'**
  String get signupCreatorCatalogPieces;

  /// No description provided for @signupCreatorCreateAccount.
  ///
  /// In fr, this message translates to:
  /// **'Créer mon compte'**
  String get signupCreatorCreateAccount;

  /// No description provided for @signupCreatorForBrands.
  ///
  /// In fr, this message translates to:
  /// **'Pour les marques & créateurs'**
  String get signupCreatorForBrands;

  /// No description provided for @signupCreatorIntro.
  ///
  /// In fr, this message translates to:
  /// **'Ton univers marque s\'affiche là où les gens découvrent déjà des styles : même fil que les utilisateurs, avec ta boutique et tes publications.'**
  String get signupCreatorIntro;

  /// No description provided for @signupCreatorSpaceTitle.
  ///
  /// In fr, this message translates to:
  /// **'Espace créateur'**
  String get signupCreatorSpaceTitle;

  /// No description provided for @signupCreatorSwipeRight.
  ///
  /// In fr, this message translates to:
  /// **'Glisse vers la droite'**
  String get signupCreatorSwipeRight;

  /// No description provided for @signupCreatorSwipeRightBadge.
  ///
  /// In fr, this message translates to:
  /// **'Swipe droite'**
  String get signupCreatorSwipeRightBadge;

  /// No description provided for @snackActionDressing.
  ///
  /// In fr, this message translates to:
  /// **'Dressing'**
  String get snackActionDressing;

  /// No description provided for @snackActionOutfits.
  ///
  /// In fr, this message translates to:
  /// **'Outfits'**
  String get snackActionOutfits;

  /// No description provided for @startupErrorTitle.
  ///
  /// In fr, this message translates to:
  /// **'Erreur au démarrage'**
  String get startupErrorTitle;

  /// No description provided for @statBest.
  ///
  /// In fr, this message translates to:
  /// **'Best'**
  String get statBest;

  /// No description provided for @statGarments.
  ///
  /// In fr, this message translates to:
  /// **'Vêtements'**
  String get statGarments;

  /// No description provided for @statStreak.
  ///
  /// In fr, this message translates to:
  /// **'Streak'**
  String get statStreak;

  /// No description provided for @statWorn.
  ///
  /// In fr, this message translates to:
  /// **'Portes'**
  String get statWorn;

  /// No description provided for @styleAudacity.
  ///
  /// In fr, this message translates to:
  /// **'Audace'**
  String get styleAudacity;

  /// No description provided for @styleAudacityHigh.
  ///
  /// In fr, this message translates to:
  /// **'Audacieux'**
  String get styleAudacityHigh;

  /// No description provided for @styleAudacityLow.
  ///
  /// In fr, this message translates to:
  /// **'Sobre'**
  String get styleAudacityLow;

  /// No description provided for @styleCasual.
  ///
  /// In fr, this message translates to:
  /// **'Décontracté'**
  String get styleCasual;

  /// No description provided for @styleClassy.
  ///
  /// In fr, this message translates to:
  /// **'Classe'**
  String get styleClassy;

  /// No description provided for @styleColorful.
  ///
  /// In fr, this message translates to:
  /// **'Coloré'**
  String get styleColorful;

  /// No description provided for @styleComfortBalanced.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai des bases'**
  String get styleComfortBalanced;

  /// No description provided for @styleComfortBeginner.
  ///
  /// In fr, this message translates to:
  /// **'Je débute'**
  String get styleComfortBeginner;

  /// No description provided for @styleComfortConfident.
  ///
  /// In fr, this message translates to:
  /// **'Je suis à l\'aise'**
  String get styleComfortConfident;

  /// No description provided for @styleComfortTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton rapport à la mode'**
  String get styleComfortTitle;

  /// No description provided for @styleEvening.
  ///
  /// In fr, this message translates to:
  /// **'Soirée'**
  String get styleEvening;

  /// No description provided for @styleGoalInspiration.
  ///
  /// In fr, this message translates to:
  /// **'Trouver l\'inspiration'**
  String get styleGoalInspiration;

  /// No description provided for @styleGoalRefine.
  ///
  /// In fr, this message translates to:
  /// **'Affiner mon style'**
  String get styleGoalRefine;

  /// No description provided for @styleGoalTrack.
  ///
  /// In fr, this message translates to:
  /// **'Suivre ce que je porte'**
  String get styleGoalTrack;

  /// No description provided for @styleGoalWardrobe.
  ///
  /// In fr, this message translates to:
  /// **'Gérer ma garde-robe'**
  String get styleGoalWardrobe;

  /// No description provided for @styleIdentityCasual.
  ///
  /// In fr, this message translates to:
  /// **'Casual'**
  String get styleIdentityCasual;

  /// No description provided for @styleIdentityClassic.
  ///
  /// In fr, this message translates to:
  /// **'Classique'**
  String get styleIdentityClassic;

  /// No description provided for @styleIdentityColorful.
  ///
  /// In fr, this message translates to:
  /// **'Coloré'**
  String get styleIdentityColorful;

  /// No description provided for @styleIdentityEvening.
  ///
  /// In fr, this message translates to:
  /// **'Soirée'**
  String get styleIdentityEvening;

  /// No description provided for @styleIdentityMinimal.
  ///
  /// In fr, this message translates to:
  /// **'Minimal'**
  String get styleIdentityMinimal;

  /// No description provided for @styleIdentityProfessional.
  ///
  /// In fr, this message translates to:
  /// **'Professionnel'**
  String get styleIdentityProfessional;

  /// No description provided for @styleIdentitySport.
  ///
  /// In fr, this message translates to:
  /// **'Sport'**
  String get styleIdentitySport;

  /// No description provided for @styleIdentityStreetwear.
  ///
  /// In fr, this message translates to:
  /// **'Streetwear'**
  String get styleIdentityStreetwear;

  /// No description provided for @styleIdentityTitle.
  ///
  /// In fr, this message translates to:
  /// **'Ton style'**
  String get styleIdentityTitle;

  /// No description provided for @styleOnboardingContinue.
  ///
  /// In fr, this message translates to:
  /// **'Continuer'**
  String get styleOnboardingContinue;

  /// No description provided for @styleOnboardingSkip.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get styleOnboardingSkip;

  /// No description provided for @styleOnboardingSkipAll.
  ///
  /// In fr, this message translates to:
  /// **'Passer la personnalisation'**
  String get styleOnboardingSkipAll;

  /// No description provided for @styleOnboardingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Personnalise uniSaps'**
  String get styleOnboardingTitle;

  /// No description provided for @styleProfessional.
  ///
  /// In fr, this message translates to:
  /// **'Professionnel'**
  String get styleProfessional;

  /// No description provided for @styleSettingsReset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get styleSettingsReset;

  /// No description provided for @styleSettingsSave.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get styleSettingsSave;

  /// No description provided for @styleSettingsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Style & préférences'**
  String get styleSettingsTitle;

  /// No description provided for @styleSimple.
  ///
  /// In fr, this message translates to:
  /// **'Simple'**
  String get styleSimple;

  /// No description provided for @styleSporty.
  ///
  /// In fr, this message translates to:
  /// **'Sportif'**
  String get styleSporty;

  /// No description provided for @styleStreetwear.
  ///
  /// In fr, this message translates to:
  /// **'Streetwear'**
  String get styleStreetwear;

  /// No description provided for @stylistRationaleFallback.
  ///
  /// In fr, this message translates to:
  /// **'Look équilibré pour ta garde-robe.'**
  String get stylistRationaleFallback;

  /// No description provided for @teasePremiumAiSuggestions.
  ///
  /// In fr, this message translates to:
  /// **'Suggestions IA'**
  String get teasePremiumAiSuggestions;

  /// No description provided for @teasePremiumDiscover.
  ///
  /// In fr, this message translates to:
  /// **'Découvrir'**
  String get teasePremiumDiscover;

  /// No description provided for @tutorialDressingDesc.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute un vêtement pour remplir ton dressing.'**
  String get tutorialDressingDesc;

  /// No description provided for @tutorialDressingTitle.
  ///
  /// In fr, this message translates to:
  /// **'Commence par ton dressing'**
  String get tutorialDressingTitle;

  /// No description provided for @tutorialInspoDesc.
  ///
  /// In fr, this message translates to:
  /// **'Découvre les looks des autres et partage le tien.'**
  String get tutorialInspoDesc;

  /// No description provided for @tutorialInspoTitle.
  ///
  /// In fr, this message translates to:
  /// **'Inspire-toi et publie'**
  String get tutorialInspoTitle;

  /// No description provided for @tutorialOutfitsDesc.
  ///
  /// In fr, this message translates to:
  /// **'Assemble tes vêtements en un look complet.'**
  String get tutorialOutfitsDesc;

  /// No description provided for @tutorialOutfitsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Crée ton premier outfit'**
  String get tutorialOutfitsTitle;

  /// No description provided for @tutorialPublishDesc.
  ///
  /// In fr, this message translates to:
  /// **'Depuis Inspiration, partage la photo de ton outfit du jour (1 par jour).'**
  String get tutorialPublishDesc;

  /// No description provided for @tutorialPublishTitle.
  ///
  /// In fr, this message translates to:
  /// **'Publie ton look du jour'**
  String get tutorialPublishTitle;

  /// No description provided for @userProfileAccept.
  ///
  /// In fr, this message translates to:
  /// **'Accepter'**
  String get userProfileAccept;

  /// No description provided for @userProfileAddFriend.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter en ami'**
  String get userProfileAddFriend;

  /// No description provided for @userProfileEmptyDressing.
  ///
  /// In fr, this message translates to:
  /// **'Dressing vide'**
  String get userProfileEmptyDressing;

  /// No description provided for @userProfileFriend.
  ///
  /// In fr, this message translates to:
  /// **'Ami'**
  String get userProfileFriend;

  /// No description provided for @userProfileFriendsLoadFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de charger la liste : {error}'**
  String userProfileFriendsLoadFailed(Object error);

  /// No description provided for @userProfileFriendsOf.
  ///
  /// In fr, this message translates to:
  /// **'Amis de @{username}'**
  String userProfileFriendsOf(Object username);

  /// No description provided for @userProfileNoFriendsYet.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ami pour le moment'**
  String get userProfileNoFriendsYet;

  /// No description provided for @userProfileNoLinkedPieces.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pièce liée'**
  String get userProfileNoLinkedPieces;

  /// No description provided for @userProfileNoPosts.
  ///
  /// In fr, this message translates to:
  /// **'Aucun post'**
  String get userProfileNoPosts;

  /// No description provided for @userProfileNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur introuvable'**
  String get userProfileNotFound;

  /// No description provided for @userProfileOtherPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Autres photos'**
  String get userProfileOtherPhotos;

  /// No description provided for @userProfilePending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get userProfilePending;

  /// No description provided for @userProfilePieces.
  ///
  /// In fr, this message translates to:
  /// **'Pièces'**
  String get userProfilePieces;

  /// No description provided for @userProfilePrivate.
  ///
  /// In fr, this message translates to:
  /// **'Privé'**
  String get userProfilePrivate;

  /// No description provided for @userProfilePrivateViewBody.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute cet utilisateur en ami pour voir son contenu.'**
  String get userProfilePrivateViewBody;

  /// No description provided for @userProfileRequestSent.
  ///
  /// In fr, this message translates to:
  /// **'Demande envoyée'**
  String get userProfileRequestSent;

  /// No description provided for @userProfileTimesWorn.
  ///
  /// In fr, this message translates to:
  /// **'{count}x porté'**
  String userProfileTimesWorn(Object count);

  /// No description provided for @weatherApproxPositionUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Position approximative - mis à jour à {time}'**
  String weatherApproxPositionUpdated(Object time);

  /// No description provided for @weatherClose.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get weatherClose;

  /// No description provided for @weatherCloudy.
  ///
  /// In fr, this message translates to:
  /// **'Nuageux'**
  String get weatherCloudy;

  /// No description provided for @weatherFeelsLike.
  ///
  /// In fr, this message translates to:
  /// **'Ressenti'**
  String get weatherFeelsLike;

  /// No description provided for @weatherFeelsLikeShort.
  ///
  /// In fr, this message translates to:
  /// **'Ressenti'**
  String get weatherFeelsLikeShort;

  /// No description provided for @weatherFetchFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de récupérer la météo.'**
  String get weatherFetchFailed;

  /// No description provided for @weatherFog.
  ///
  /// In fr, this message translates to:
  /// **'Brouillard'**
  String get weatherFog;

  /// No description provided for @weatherHourNow.
  ///
  /// In fr, this message translates to:
  /// **'{hour}h'**
  String weatherHourNow(Object hour);

  /// No description provided for @weatherHourly.
  ///
  /// In fr, this message translates to:
  /// **'Heure par heure'**
  String get weatherHourly;

  /// No description provided for @weatherHourlyUnavailable.
  ///
  /// In fr, this message translates to:
  /// **'Données horaires indisponibles.'**
  String get weatherHourlyUnavailable;

  /// No description provided for @weatherHumidity.
  ///
  /// In fr, this message translates to:
  /// **'Humidité'**
  String get weatherHumidity;

  /// No description provided for @weatherLoadingLocation.
  ///
  /// In fr, this message translates to:
  /// **'Localisation et récupération de la météo…'**
  String get weatherLoadingLocation;

  /// No description provided for @weatherLocationParis.
  ///
  /// In fr, this message translates to:
  /// **'Paris (approx.)'**
  String get weatherLocationParis;

  /// No description provided for @weatherLocationPosition.
  ///
  /// In fr, this message translates to:
  /// **'Position'**
  String get weatherLocationPosition;

  /// No description provided for @weatherModerateRainRisk.
  ///
  /// In fr, this message translates to:
  /// **'Risque modéré de pluie (max {pop} %).'**
  String weatherModerateRainRisk(Object pop);

  /// No description provided for @weatherNice.
  ///
  /// In fr, this message translates to:
  /// **'Beau temps'**
  String get weatherNice;

  /// No description provided for @weatherNightInProgress.
  ///
  /// In fr, this message translates to:
  /// **'Nuit en cours'**
  String get weatherNightInProgress;

  /// No description provided for @weatherNoRainToday.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pluie prévue aujourd\'hui.'**
  String get weatherNoRainToday;

  /// No description provided for @weatherNow.
  ///
  /// In fr, this message translates to:
  /// **'En ce moment'**
  String get weatherNow;

  /// No description provided for @weatherOpenMeteoUpdated.
  ///
  /// In fr, this message translates to:
  /// **'Données Open-Meteo - mis à jour à {time}'**
  String weatherOpenMeteoUpdated(Object time);

  /// No description provided for @weatherPartlyClear.
  ///
  /// In fr, this message translates to:
  /// **'Partiellement dégagé'**
  String get weatherPartlyClear;

  /// No description provided for @weatherRain.
  ///
  /// In fr, this message translates to:
  /// **'Pluie'**
  String get weatherRain;

  /// No description provided for @weatherRainLikelyFrom.
  ///
  /// In fr, this message translates to:
  /// **'Pluie probable à partir de {time} (max {pop} %, ~{mm} mm).'**
  String weatherRainLikelyFrom(Object mm, Object pop, Object time);

  /// No description provided for @weatherRefresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser à ma position'**
  String get weatherRefresh;

  /// No description provided for @weatherSnow.
  ///
  /// In fr, this message translates to:
  /// **'Neige'**
  String get weatherSnow;

  /// No description provided for @weatherStorm.
  ///
  /// In fr, this message translates to:
  /// **'Orage'**
  String get weatherStorm;

  /// No description provided for @weatherSunCourse.
  ///
  /// In fr, this message translates to:
  /// **'Course du soleil'**
  String get weatherSunCourse;

  /// No description provided for @weatherSunrise.
  ///
  /// In fr, this message translates to:
  /// **'Lever'**
  String get weatherSunrise;

  /// No description provided for @weatherSunset.
  ///
  /// In fr, this message translates to:
  /// **'Coucher'**
  String get weatherSunset;

  /// No description provided for @weatherTodayMinMax.
  ///
  /// In fr, this message translates to:
  /// **'Auj. {range}'**
  String weatherTodayMinMax(Object range);

  /// No description provided for @weatherVariable.
  ///
  /// In fr, this message translates to:
  /// **'Variable'**
  String get weatherVariable;

  /// No description provided for @weatherWind.
  ///
  /// In fr, this message translates to:
  /// **'Vent'**
  String get weatherWind;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
