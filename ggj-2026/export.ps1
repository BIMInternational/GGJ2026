# Script d'export automatique pour itch.io
# Necessite Godot installe et accessible via la ligne de commande

param(
    [string]$GodotPath = "",
    [switch]$SkipWeb,
    [switch]$SkipWindows,
    [switch]$SkipLinux,
    [switch]$SkipMac
)

$ErrorActionPreference = "Stop"
$ProjectPath = $PSScriptRoot
$ProjectFile = Join-Path $ProjectPath "project.godot"

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Export GGJ2026 pour itch.io" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Demander l'emplacement de Godot si non specifie
if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    Write-Host "Ou se trouve votre executable Godot ?" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Emplacements courants :" -ForegroundColor Gray
    Write-Host "  - C:\Users\$env:USERNAME\Documents\Perso\Godot\Godot_v4.5.1-stable_win64.exe" -ForegroundColor Gray
    Write-Host "  - C:\Godot\Godot_v4.5.1-stable_win64.exe" -ForegroundColor Gray
    Write-Host "  - Tapez 'godot' si Godot est dans votre PATH" -ForegroundColor Gray
    Write-Host ""
    $GodotPath = Read-Host "Chemin vers Godot"
    
    if ([string]::IsNullOrWhiteSpace($GodotPath)) {
        Write-Host "Erreur : Aucun chemin specifie !" -ForegroundColor Red
        exit 1
    }
}

# Verifier que Godot est disponible
Write-Host ""
Write-Host "Verification de Godot..." -ForegroundColor Cyan
try {
    $godotVersion = & $GodotPath --version 2>&1
    Write-Host "Godot trouve : $godotVersion" -ForegroundColor Green
} catch {
    Write-Host "Erreur : Godot n'est pas trouve au chemin specifie !" -ForegroundColor Red
    Write-Host "  Chemin utilise : $GodotPath" -ForegroundColor Yellow
    Write-Host "  Veuillez verifier le chemin et reessayer." -ForegroundColor Yellow
    exit 1
}

# Verifier que le projet existe
if (-not (Test-Path $ProjectFile)) {
    Write-Host "Erreur : project.godot non trouve dans ggj-2026/" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "CONTROLE DE SECURITE PRE-DECOLLAGE" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Inspection en cours... (oui, meme a 3h du matin !)" -ForegroundColor Gray
Write-Host ""

$warnings = @()
$hasIssues = $false

# Verifier les polices externes (probleme courant avec export Web)
if (-not $SkipWeb) {
    Write-Host "Brigade anti-polices exotiques en action..." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 300
    $fontExtensions = @("*.ttf", "*.otf", "*.woff", "*.woff2")
    $fontsDir = Join-Path $ProjectPath "assets\fonts"
    
    if (Test-Path $fontsDir) {
        $fontFiles = Get-ChildItem -Path $fontsDir -Include $fontExtensions -Recurse -File
        
        if ($fontFiles.Count -gt 0) {
            Write-Host "  Hmmm, $($fontFiles.Count) police(s) custom detectee(s)..." -ForegroundColor Yellow
            Write-Host "  (Elles se croient plus belles qu'Arial ?)" -ForegroundColor Gray
            
            # Verifier les fichiers .import pour les polices
            $fontsWithoutImport = @()
            foreach ($font in $fontFiles) {
                $importFile = "$($font.FullName).import"
                if (-not (Test-Path $importFile)) {
                    $fontsWithoutImport += $font.Name
                }
            }
            
            if ($fontsWithoutImport.Count -gt 0) {
                Write-Host ""
                Write-Host "  ALERTE ROUGE ! Des polices rebelles sans .import !" -ForegroundColor Red
                Write-Host "  (Elles vont faire crasher le Web comme des sauvages)" -ForegroundColor Yellow
                foreach ($fontName in $fontsWithoutImport) {
                    Write-Host "    - $fontName (mode anarchie activee)" -ForegroundColor Gray
                }
                $warnings += "Polices rebelles detectees - risque de chaos sur itch.io"
                $hasIssues = $true
                Write-Host ""
                Write-Host "  FIX RAPIDE : Ouvrez Godot, clic droit sur la police > Reimport" -ForegroundColor Cyan
            } else {
                Write-Host "  Toutes les polices sont sages et ont leur .import" -ForegroundColor Green
                Write-Host "  (Bravo, elles ont ete bien elevees !)" -ForegroundColor Gray
            }
            
            Write-Host ""
            Write-Host "  CONSEIL DE GRAND-MERE : Pour le Web, c'est mieux avec :" -ForegroundColor Yellow
            Write-Host "  - Des polices systeme (Arial, elles sont pas belles mais fiables)" -ForegroundColor Gray
            Write-Host "  - Les polices de Godot (deja integrees, zero galere)" -ForegroundColor Gray
            Write-Host "  - L'option 'Compress' activee (sinon c'est lourd comme un elephant)" -ForegroundColor Gray
            Write-Host ""
        } else {
            Write-Host "  Aucune police exotique detectee" -ForegroundColor Green
            Write-Host "  (Vous etes minimaliste ou juste presses ? Les deux ?)" -ForegroundColor Gray
        }
    }
}

# Verifier la taille du projet (important pour Web)
if (-not $SkipWeb) {
    Write-Host "Pesage des assets (comme a la poste, mais en bits)..." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 300
    $assetsSize = 0
    $assetsDir = Join-Path $ProjectPath "assets"
    
    if (Test-Path $assetsDir) {
        $assetsSize = (Get-ChildItem -Path $assetsDir -Recurse -File | Measure-Object -Property Length -Sum).Sum / 1MB
        
        if ($assetsSize -gt 50) {
            Write-Host "  OUPS ! Vos assets pesent $([math]::Round($assetsSize, 2)) MB !" -ForegroundColor Yellow
            Write-Host "  (C'est lourd comme un hippopotame en vacances)" -ForegroundColor Gray
            Write-Host "  Le chargement Web va etre aussi lent qu'un escargot enrhume..." -ForegroundColor Yellow
            $warnings += "Assets volumineux ($([math]::Round($assetsSize, 2)) MB) - temps de chargement rallonge"
        } else {
            Write-Host "  Taille des assets : $([math]::Round($assetsSize, 2)) MB" -ForegroundColor Green
            Write-Host "  (Legers comme une plume, parfait pour le Web !)" -ForegroundColor Gray
        }
    }
}

# Verifier les fichiers audio (format important pour Web)
if (-not $SkipWeb) {
    Write-Host "Ecoute des fichiers audio (avec les oreilles du script)..." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 300
    $audioFormats = @("*.wav")
    $audioDir = Join-Path $ProjectPath "assets"
    
    if (Test-Path $audioDir) {
        $wavFiles = Get-ChildItem -Path $audioDir -Include $audioFormats -Recurse -File
        
        if ($wavFiles.Count -gt 0) {
            $totalWavSize = ($wavFiles | Measure-Object -Property Length -Sum).Sum / 1MB
            if ($totalWavSize -gt 10) {
                Write-Host "  Des fichiers WAV enormes detectes ! ($([math]::Round($totalWavSize, 2)) MB)" -ForegroundColor Yellow
                Write-Host "  (Le WAV c'est bien pour les audiophiles, pas pour le Web !)" -ForegroundColor Gray
                Write-Host "  Conseil : Convertissez en .ogg, ca prend 10x moins de place" -ForegroundColor Cyan
                $warnings += "Fichiers WAV XXL ($([math]::Round($totalWavSize, 2)) MB) - convertir en .ogg recommande"
            } else {
                Write-Host "  Fichiers audio : Taille raisonnable" -ForegroundColor Green
                Write-Host "  (Mais le .ogg c'est quand meme mieux, juste pour info)" -ForegroundColor Gray
            }
        } else {
            Write-Host "  Pas de gros WAV detectes" -ForegroundColor Green
            Write-Host "  (Vous etes sages, ou vous avez deja tout en .ogg ?)" -ForegroundColor Gray
        }
    }
}

Write-Host ""

if ($warnings.Count -gt 0) {
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host "LE DETECTEUR DE PROBLEMES A SONNE !" -ForegroundColor Yellow
    Write-Host "==================================================" -ForegroundColor Yellow
    Write-Host ""
    foreach ($warning in $warnings) {
        Write-Host "  ! $warning" -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host "Ces trucs peuvent faire raler itch.io..." -ForegroundColor Yellow
    Write-Host "Mais bon, on est en Game Jam, on corrigera plus tard (ou jamais) !" -ForegroundColor Gray
    Write-Host ""
}

Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "RECAPITULATIF AVANT EXPORT" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Projet : GGJ2026" -ForegroundColor White
Write-Host "Chemin : $ProjectPath" -ForegroundColor Gray
Write-Host ""
Write-Host "Plateformes a exporter :" -ForegroundColor White

$platformesToExport = @()
if (-not $SkipWeb) { 
    Write-Host "  - Web (HTML5) - Jouable dans le navigateur" -ForegroundColor Green
    $platformesToExport += "Web"
}
if (-not $SkipWindows) { 
    Write-Host "  - Windows (telechargeable)" -ForegroundColor Green
    $platformesToExport += "Windows"
}
if (-not $SkipLinux) { 
    Write-Host "  - Linux (telechargeable)" -ForegroundColor Green
    $platformesToExport += "Linux"
}
if (-not $SkipMac) { 
    Write-Host "  - macOS (telechargeable)" -ForegroundColor Green
    $platformesToExport += "macOS"
}

if ($platformesToExport.Count -eq 0) {
    Write-Host "Aucune plateforme selectionnee !" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "IMPORTANT : Avez-vous installe les templates d'export Godot ?" -ForegroundColor Yellow
Write-Host "  (Editeur > Gerer les modeles d'exportation > Telecharger et installer)" -ForegroundColor Gray
Write-Host ""
$confirmation = Read-Host "Continuer l'export ? (O/N)"

if ($confirmation -ne "O" -and $confirmation -ne "o" -and $confirmation -ne "Y" -and $confirmation -ne "y") {
    Write-Host ""
    Write-Host "Export annule." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Demarrage des exports..." -ForegroundColor Cyan
Write-Host ""

# Fonction pour exporter une plateforme
function Export-Platform {
    param(
        [string]$PresetName,
        [string]$OutputPath,
        [string]$DisplayName
    )
    
    Write-Host "Exportation : $DisplayName..." -ForegroundColor Yellow
    
    try {
        # Creer le dossier de sortie s'il n'existe pas
        $outputDir = Split-Path $OutputPath -Parent
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
        
        # Exporter
        & $GodotPath --headless --export-release $PresetName $OutputPath --path $ProjectPath 2>&1 | Out-Null
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  $DisplayName exporte avec succes" -ForegroundColor Green
            return $true
        } else {
            Write-Host "  Echec de l'export $DisplayName" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "  Erreur lors de l'export $DisplayName : $_" -ForegroundColor Red
        return $false
    }
}

$successCount = 0
$totalCount = 0

# Export Web
if (-not $SkipWeb) {
    $totalCount++
    $webPath = Join-Path $ProjectPath "publish\web\index.html"
    if (Export-Platform "Web" $webPath "Web (HTML5)") {
        $successCount++
        
        # Creer l'archive Web pour itch.io
        Write-Host "  Creation de l'archive Web pour itch.io..." -ForegroundColor Yellow
        $webDir = Join-Path $ProjectPath "publish\web"
        $publishDir = Join-Path $ProjectPath "publish"
        $webZipPath = Join-Path $publishDir "GGJ2026-Web.zip"
        
        if (Test-Path $webZipPath) {
            Remove-Item $webZipPath -Force
        }
        
        Compress-Archive -Path "$webDir\*" -DestinationPath $webZipPath -Force
        $zipSizeMB = [math]::Round((Get-Item $webZipPath).Length / 1MB, 2)
        Write-Host "  Archive creee : publish/GGJ2026-Web.zip ($zipSizeMB MB)" -ForegroundColor Green
    }
}

# Export Windows
if (-not $SkipWindows) {
    $totalCount++
    $windowsPath = Join-Path $ProjectPath "publish\windows\GGJ2026.exe"
    if (Export-Platform "Windows Desktop" $windowsPath "Windows") {
        $successCount++
        
        # Creer un ZIP pour Windows
        Write-Host "  Creation de l'archive Windows..." -ForegroundColor Yellow
        $windowsDir = Join-Path $ProjectPath "publish\windows"
        $zipPath = Join-Path $ProjectPath "publish\GGJ2026-Windows.zip"
        
        if (Test-Path $zipPath) {
            Remove-Item $zipPath -Force
        }
        
        Compress-Archive -Path "$windowsDir\*" -DestinationPath $zipPath -Force
        Write-Host "  Archive creee : publish/GGJ2026-Windows.zip" -ForegroundColor Green
    }
}

# Export Linux
if (-not $SkipLinux) {
    $totalCount++
    $linuxPath = Join-Path $ProjectPath "publish\linux\GGJ2026.x86_64"
    if (Export-Platform "Linux" $linuxPath "Linux") {
        $successCount++
        
        # Creer un ZIP pour Linux
        Write-Host "  Creation de l'archive Linux..." -ForegroundColor Yellow
        $linuxDir = Join-Path $ProjectPath "publish\linux"
        $zipPath = Join-Path $ProjectPath "publish\GGJ2026-Linux.zip"
        
        if (Test-Path $zipPath) {
            Remove-Item $zipPath -Force
        }
        
        Compress-Archive -Path "$linuxDir\*" -DestinationPath $zipPath -Force
        Write-Host "  Archive creee : publish/GGJ2026-Linux.zip" -ForegroundColor Green
    }
}

# Export macOS
if (-not $SkipMac) {
    $totalCount++
    $macPath = Join-Path $ProjectPath "publish\mac\GGJ2026.zip"
    if (Export-Platform "macOS" $macPath "macOS") {
        $successCount++
    }
}

Write-Host ""
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Resume de l'export" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "$successCount/$totalCount plateformes exportees avec succes" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })
Write-Host ""

if ($successCount -gt 0) {
    Write-Host ""
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host "BRAVO ! VOTRE JEU EST PRET !" -ForegroundColor Green
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
    
    $webZipPath = Join-Path $ProjectPath "publish\GGJ2026-Web.zip"
    
    if (-not $SkipWeb -and (Test-Path $webZipPath)) {
        $zipSizeMB = [math]::Round((Get-Item $webZipPath).Length / 1MB, 2)
        
        Write-Host "Fichier genere : publish/GGJ2026-Web.zip ($zipSizeMB MB)" -ForegroundColor White
        Write-Host "Emplacement : $webZipPath" -ForegroundColor Gray
        Write-Host ""
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host "PUBLICATION SUR ITCH.IO - MODE GAME JAM !" -ForegroundColor Cyan
        Write-Host "==================================================" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Allez, plus que quelques clics et votre jeu sera en ligne !" -ForegroundColor Yellow
        Write-Host ""
        
        Write-Host "ETAPE 1 : CONNECTEZ-VOUS A ITCH.IO" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  1. Ouvrez votre navigateur" -ForegroundColor White
        Write-Host "  2. Allez sur : https://itch.io" -ForegroundColor Cyan
        Write-Host "  3. Cliquez sur 'Log in' (en haut a droite)" -ForegroundColor White
        Write-Host "  4. Connectez-vous avec vos identifiants" -ForegroundColor White
        Write-Host ""
        Write-Host "  Pas encore de compte ? Creez-en un, c'est rapide !" -ForegroundColor Gray
        Write-Host ""
        
        $step1 = Read-Host "Vous etes connecte a itch.io ? (O/N)"
        if ($step1 -ne "O" -and $step1 -ne "o") {
            Write-Host ""
            Write-Host "Prenez votre temps, on vous attend ici..." -ForegroundColor Yellow
            Write-Host "Tapez O quand c'est bon !" -ForegroundColor Cyan
            Write-Host ""
            $step1 = Read-Host "C'est bon maintenant ? (O/N)"
            if ($step1 -ne "O" -and $step1 -ne "o") {
                Write-Host ""
                Write-Host "OK, revenez quand vous serez pret !" -ForegroundColor Yellow
                Write-Host "Le fichier ZIP est la : $webZipPath" -ForegroundColor Cyan
                Write-Host ""
                exit 0
            }
        }
        
        Write-Host ""
        Write-Host "Super ! On continue..." -ForegroundColor Green
        Write-Host ""
        
        Write-Host "ETAPE 2 : CREEZ VOTRE PAGE DE JEU" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  1. Cliquez sur votre nom (en haut a droite)" -ForegroundColor White
        Write-Host "  2. Selectionnez 'Dashboard'" -ForegroundColor White
        Write-Host "  3. Cliquez sur le gros bouton 'Create new project'" -ForegroundColor Cyan
        Write-Host ""
        
        $step2 = Read-Host "Vous etes sur la page de creation ? (O/N)"
        if ($step2 -ne "O" -and $step2 -ne "o") {
            Write-Host ""
            Write-Host "Pas de panique ! Cherchez bien le bouton 'Create new project'" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Appuyez sur Entree quand vous l'avez trouve..."
        }
        
        Write-Host ""
        Write-Host "Nickel ! Passons aux infos..." -ForegroundColor Green
        Write-Host ""
        
        Write-Host "ETAPE 3 : REMPLISSEZ LES INFOS DE BASE" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Title :" -ForegroundColor White
        Write-Host "    -> Tapez le nom de votre jeu (ex: GGJ2026)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Project URL :" -ForegroundColor White
        Write-Host "    -> Ca sera : votre-nom.itch.io/nom-du-jeu" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Classification :" -ForegroundColor White
        Write-Host "    -> Selectionnez 'Games'" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Kind of project :" -ForegroundColor White
        Write-Host "    -> Cochez 'HTML' (SUPER IMPORTANT !)" -ForegroundColor Cyan
        Write-Host ""
        
        $step3 = Read-Host "Tout est rempli ? (O/N)"
        if ($step3 -ne "O" -and $step3 -ne "o") {
            Write-Host ""
            Write-Host "Prenez votre temps pour trouver un nom cool !" -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Appuyez sur Entree quand c'est fait..."
        }
        
        Write-Host ""
        Write-Host "Excellent ! Maintenant la partie cruciale..." -ForegroundColor Green
        Write-Host ""
        
        Write-Host "ETAPE 4 : UPLOADEZ VOTRE JEU (LA PARTIE IMPORTANTE !)" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  1. Descendez jusqu'a la section 'Uploads'" -ForegroundColor White
        Write-Host ""
        Write-Host "  2. Cliquez sur 'Upload files'" -ForegroundColor White
        Write-Host ""
        Write-Host "  3. COPIEZ ce chemin et collez-le dans la fenetre :" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "     $webZipPath" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "     OU cherchez manuellement :" -ForegroundColor Gray
        Write-Host "     - Naviguez vers le dossier ggj-2026/publish/" -ForegroundColor Gray
        Write-Host "     - Selectionnez GGJ2026-Web.zip" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  4. TRES IMPORTANT : Cochez la case" -ForegroundColor Yellow
        Write-Host "     'This file will be played in the browser'" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  5. Dans 'Embed options', definissez :" -ForegroundColor White
        Write-Host "     - Viewport dimensions : 1280 x 720" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  6. Cliquez sur 'Save' en bas de la section" -ForegroundColor White
        Write-Host ""
        
        $step4 = Read-Host "Le fichier est uploade et 'played in browser' est coche ? (O/N)"
        if ($step4 -ne "O" -and $step4 -ne "o") {
            Write-Host ""
            Write-Host "ATTENTION : Sans cocher 'played in browser', le jeu ne sera pas jouable !" -ForegroundColor Red
            Write-Host "Verifiez bien que la case est cochee avant de continuer." -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Appuyez sur Entree quand c'est bon..."
        }
        
        Write-Host ""
        Write-Host "Parfait ! Le plus dur est fait !" -ForegroundColor Green
        Write-Host ""
        
        Write-Host "ETAPE 5 : RENDEZ-LE BEAU !" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  Description :" -ForegroundColor White
        Write-Host "    -> Decrivez votre jeu (theme de la jam, gameplay, etc.)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  Screenshots / Gameplay :" -ForegroundColor White
        Write-Host "    -> Ajoutez 3-5 captures d'ecran de votre jeu" -ForegroundColor Gray
        Write-Host "    -> Tip : Faites F12 dans Godot pour prendre des screenshots !" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Cover image :" -ForegroundColor White
        Write-Host "    -> Image principale (630x500 pixels recommande)" -ForegroundColor Gray
        Write-Host ""
        
        $step5 = Read-Host "Vous avez ajoute des screenshots et une description ? (O/N)"
        if ($step5 -ne "O" -and $step5 -ne "o") {
            Write-Host ""
            Write-Host "C'est vrai que c'est la fin de la jam, on est tous fatigues..." -ForegroundColor Yellow
            Write-Host "Mais 2-3 screenshots + quelques lignes de description, ca fait la diff !" -ForegroundColor Cyan
            Write-Host ""
            $skip5 = Read-Host "Voulez-vous vraiment passer cette etape ? (O/N)"
            if ($skip5 -eq "O" -or $skip5 -eq "o") {
                Write-Host "Ok, on passe ! Mais pensez-y plus tard..." -ForegroundColor Gray
            }
            else {
                Read-Host "Appuyez sur Entree quand c'est fait..."
            }
        }
        
        Write-Host ""
        Write-Host "Super ! On arrive au bout !" -ForegroundColor Green
        Write-Host ""
        
        Write-Host "ETAPE 6 : PARTAGEZ AVEC LE MONDE !" -ForegroundColor Green
        Write-Host "==========================================" -ForegroundColor Green
        Write-Host ""
        Write-Host "  1. Descendez tout en bas" -ForegroundColor White
        Write-Host ""
        Write-Host "  2. Dans 'Visibility & access', choisissez :" -ForegroundColor White
        Write-Host "     - Public : Tout le monde peut le voir" -ForegroundColor Gray
        Write-Host "     - Restricted : Uniquement avec le lien (ideal pour tester)" -ForegroundColor Cyan
        Write-Host "     - Draft : Brouillon (pour finir plus tard)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "  3. Cliquez sur le gros bouton 'Save & view page'" -ForegroundColor Cyan
        Write-Host ""
        
        $step6 = Read-Host "Pret a publier ? (O/N)"
        if ($step6 -ne "O" -and $step6 -ne "o") {
            Write-Host ""
            Write-Host "Pas de stress ! Prenez votre temps pour tout verifier." -ForegroundColor Yellow
            Write-Host "Vous pouvez choisir 'Draft' pour finir plus tard, ou 'Restricted' pour tester." -ForegroundColor Cyan
            Write-Host ""
            Read-Host "Appuyez sur Entree quand vous etes pret..."
        }
        
        Write-Host ""
        Write-Host "==================================================" -ForegroundColor Magenta
        Write-Host "ET VOILA ! VOTRE JEU EST EN LIGNE !" -ForegroundColor Magenta
        Write-Host "==================================================" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "Felicitations pour cette Game Jam !" -ForegroundColor Green
        Write-Host "Partagez le lien avec vos amis et la communaute !" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Vous meritez une pause... et peut-etre une pizza ? " -ForegroundColor Cyan
        Write-Host ""
    }
    
    # Versions telechargeable
    $winZipPath = Join-Path $ProjectPath "publish\GGJ2026-Windows.zip"
    $linuxZipPath = Join-Path $ProjectPath "publish\GGJ2026-Linux.zip"
    $macZipPath = Join-Path $ProjectPath "publish\mac\GGJ2026.zip"
    
    $hasDownloadable = (-not $SkipWindows -and (Test-Path $winZipPath)) -or 
                       (-not $SkipLinux -and (Test-Path $linuxZipPath)) -or 
                       (-not $SkipMac -and (Test-Path $macZipPath))
    
    if ($hasDownloadable) {
        Write-Host "BONUS : VERSIONS TELECHARGEABLE" -ForegroundColor Yellow
        Write-Host "==========================================" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Vous pouvez aussi ajouter des versions telechargeable :" -ForegroundColor White
        Write-Host ""
        if (-not $SkipWindows -and (Test-Path $winZipPath)) {
            Write-Host "  Windows : $winZipPath" -ForegroundColor Gray
        }
        if (-not $SkipLinux -and (Test-Path $linuxZipPath)) {
            Write-Host "  Linux : $linuxZipPath" -ForegroundColor Gray
        }
        if (-not $SkipMac -and (Test-Path $macZipPath)) {
            Write-Host "  macOS : $macZipPath" -ForegroundColor Gray
        }
        Write-Host ""
        Write-Host "Upload et cochez la plateforme correspondante sur itch.io" -ForegroundColor White
        Write-Host ""
    }
    
    Write-Host "==================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Besoin d'aide ? Consultez ITCH_IO_GUIDE.md" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "Aucun export reussi." -ForegroundColor Red
    Write-Host ""
    Write-Host "VERIFICATIONS :" -ForegroundColor Yellow
    Write-Host "  1. Les templates d'export sont installes ?" -ForegroundColor White
    Write-Host "     Ouvrez Godot > Editeur > Gerer les modeles d'exportation" -ForegroundColor Gray
    Write-Host "  2. Le fichier export_presets.cfg existe dans ggj-2026/ ?" -ForegroundColor White
    Write-Host "  3. Essayez d'exporter manuellement depuis Godot pour voir l'erreur" -ForegroundColor White
}

Write-Host ""
