
# 👤 New-ADAccounts

![PowerShell](https://img.shields.io/badge/PowerShell-5.1-blue?logo=powershell) ![Active Directory](https://img.shields.io/badge/ActiveDirectory-Module-green) ![v0.1](https://img.shields.io/badge/wersja-0.1-e45959)

To repozytorium zawiera pierwszą, prototypową wersję rozwiązania do zautomatyzowanego tworzenia kont w środowisku Active Directory, połączoną z konfiguracją katalogów domowych na serwerze plików.

## Architektura rozwiązania

Skrypt działa sekwencyjnie i wykonuje operacje krok po kroku w oparciu o statyczne dane:

### 1. Generowanie i konfiguracja kont (AD)

Skrypt pobiera najwyższy numer istniejącego konta (z prefiksem `user`) w jednostce organizacyjnej `OU=Users,DC=domain,DC=pl`, a następnie wylicza kolejne numery do utworzenia.

-   Tworzy konta domyślnie wyłączone (`-Enabled $false`) z twardo wpisanym hasłem startowym.
    
-   Automatycznie przypisuje nowo utworzone konta do zdefiniowanych w skrypcie grup zabezpieczeń: `gg-group1` oraz `ug-group1`.
    

### 2. Struktura na serwerze plików (SMB)

Skrypt weryfikuje zasoby bezpośrednio na serwerze o nazwie `vm01` w lokalizacji `\\vm01\HOME$\`.

-   Oblicza odpowiedni nadrzędny katalog (format `Kxxxx`), weryfikuje jego istnienie i w razie potrzeby go tworzy.
    
-   Następnie tworzy w nim dedykowany folder docelowy dla użytkownika.
    

### 3. Uprawnienia do folderów (ACL)

Nadawanie uprawnień do folderów domowych jest oddelegowane do skryptu `Give-PermissionsToFolder.ps1`.

-   Wykorzystuje on metody `Get-Acl` oraz `Set-Acl` do utworzenia reguły typu `FileSystemAccessRule`.
    
-   Użytkownik otrzymuje uprawnienie "Modify" na poziomie wygenerowanego dla niego katalogu.
    

### 4. Udostępnianie w sieci

Proces kończy się udostępnieniem udziału przez zdalne wywołanie na serwerze `vm01`.

-   Za pomocą polecenia `New-SmbShare` tworzony jest ukryty udział sieciowy z nazwą konta i symbolem dolara (np. `user0001$`).
    
-   Na poziomie udziału nadawany jest dostęp "Change" dla grupy "Wszyscy".
    

## Wymagania

-   Moduł `ActiveDirectory`.
    
-   Serwer docelowy dla katalogów domowych.
    
-   Poświadczenia administratora z uprawnieniami do dodawania kont w AD oraz zarządzania zasobami na serwerze docelowym.
    

## Użycie

W pierwszej wersji wszystkie ścieżki i nazwy wpisane są na sztywno. Skrypt po prostu odpala się z głównego katalogu (nie przyjmuje on żadnych parametrów).

**Przykład wywołania:**

PowerShell

```
.\New-ADAccounts.ps1
```

**Zastrzeżenie!** _Skrypt wprowadza zmiany w Active Directory. Mimo że został napisany z dbałością o błędy, używasz ich na własną odpowiedzialność! Przetestuj dokładnie jego działanie na środowisku testowym przed uruchomieniem go na produkcji :)_

Autor: _Kacper Walczuk **(@walczukk)**_ | _kacper@walcz.uk_ | _walcz.uk_
