# Lancer le backend uniSaps

## Démarrage rapide

1. Ouvre un terminal PowerShell dans le dossier `backend`
2. Lance simplement :
```powershell
.\start.ps1
```

Le serveur sera disponible sur **http://localhost:8000**

## Prérequis (première fois uniquement)

### 1. Configuration Firebase

Crée un fichier `.env` dans le dossier `backend` avec le contenu suivant (copie depuis `.env.example` et modifie les valeurs) :

```env
FIREBASE_PROJECT_ID=unisaps-3ad84
FIREBASE_STORAGE_BUCKET=unisaps-3ad84.firebasestorage.app
FIREBASE_SERVICE_ACCOUNT_KEY_PATH=serviceAccountKey.json
CORS_ORIGINS=["*"]
```

### 2. Clé de compte de service Firebase

1. Va sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionne ton projet `unisaps-3ad84`
3. Va dans **Paramètres du projet** (icône ⚙️) → **Comptes de service**
4. Clique sur **Générer une nouvelle clé privée**
5. Télécharge le fichier JSON
6. Renomme-le en `serviceAccountKey.json`
7. Place-le dans le dossier `backend/`

⚠️ **Important** : Ne commit jamais ce fichier (il est déjà dans `.gitignore`)

### 3. Configuration CORS pour Firebase Storage (pour le développement web)

Pour que les images s'affichent correctement dans le navigateur, il faut configurer les règles CORS de Firebase Storage :

1. Installe `gsutil` (Google Cloud SDK) si ce n'est pas déjà fait :
   - Télécharge depuis : https://cloud.google.com/sdk/docs/install
   - Ou installe via PowerShell : `(New-Object Net.WebClient).DownloadFile("https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe", "$env:Temp\GoogleCloudSDKInstaller.exe"); & $env:Temp\GoogleCloudSDKInstaller.exe`

2. Configure `gsutil` avec ton compte Google :
   ```powershell
   gcloud auth login
   ```

3. Applique la configuration CORS :
   ```powershell
   gsutil cors set cors.json gs://unisaps-3ad84.firebasestorage.app
   ```

   Ou si tu utilises le nom complet du bucket :
   ```powershell
   gsutil cors set cors.json gs://unisaps-3ad84.appspot.com
   ```

Le fichier `cors.json` est déjà créé dans le dossier `backend/` avec les bonnes configurations pour `localhost`.

## Commandes alternatives

Si le script `start.ps1` ne fonctionne pas, tu peux utiliser :

```powershell
.\.venv\Scripts\python.exe -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Ou activer le venv puis lancer :
```powershell
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```
