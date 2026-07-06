# 👤 New-ADAccounts (SysOps)

![PowerShell](https://img.shields.io/badge/PowerShell-5.1-blue?logo=powershell) ![Active Directory](https://img.shields.io/badge/ActiveDirectory-Module-green) ![v1.3](https://img.shields.io/badge/wersja-1.3-e45959)

To repozytorium posiada zoptymalizowaną wersję rozwiązania do masowego tworzenia kont w środowisku Active Directory. Wersja 1.3 całkowicie eliminuje problemy z opóźnieniami replikacji AD dzięki operowaniu na identyfikatorach SID oraz wprowadza zautomatyzowane zarządzanie przestrzenią dyskową za pomocą FSRM.

## Architektura rozwiązania

Logika skryptu opiera się na wydajnych operacjach i natychmiastowym działaniu:

### 1. Zrzut SID (Active Directory)

Największym wąskim gardłem wcześniejszych wersji było mapowanie nazwy użytkownika na obiekt w domenie podczas nadawania uprawnień. Zostało to całkowicie zlikwidowane.

-   Skrypt wykorzystuje przełącznik `-PassThru` podczas wywoływania polecenia `New-ADUser`.
    
-   Pozwala to na natychmiastowe przechwycenie utworzonego obiektu do zmiennej `$CreatedUser` i wyodrębnienie z niego unikalnego identyfikatora: `$CreatedUser.SID.Value`.
    
-   Konto zostaje utworzone (domyślnie ze statusem `Enabled $false`) i trafia do zdefiniowanych grup zabezpieczeń (np. `gg-group1`).
    

### 2. Kuloodporne uprawnienia (Bypass replikacji)

Pomocniczy skrypt `Give-PermissionsToFolder.ps1` został przeprojektowany do pracy z identyfikatorem SID zamiast nazwy użytkownika SAMAccountName.

-   Z kodu wyleciała pętla `do...while`, która sztucznie opóźniała działanie skryptu w oczekiwaniu na replikację.
    
-   Polecenie `icacls` przyjmuje teraz bezpośrednio numer SID poprzedzony gwiazdką: `icacls $a /grant "*${CreatedUserSID}:(OI)(CI)M" /t`.
    
-   Użycie gwiazdki `*` zmusza system Windows do ominięcia weryfikacji nazwy w AD (która mogłaby się nie udać z powodu braku replikacji) i bezpośredniego wbicia uprawnienia RWX na poziomie systemu plików.
    
-   Proces kończy się wykreowaniem ukrytego udziału dla użytkownika z dostępem dla "Wszyscy".
    

### 3. Zarządzanie przestrzenią dyskową (FSRM Quotas)

Do zestawu narzędzi dołączył nowy moduł: `Set-Quotas.ps1`.

-   Po utworzeniu pełnej struktury, główny skrypt wywołuje zdalnie za pomocą `Invoke-Command` konfigurację limitów dyskowych na docelowym serwerze plików `$TargetFS`.
    
-   Skrypt sprawdza za pomocą `Get-FSRMAutoQuota`, czy dla katalogu nadrzędnego (np. `H:\HOME\K0000`) istnieje już przypisany limit.
    
-   Jeśli limitu brak, poleceniem `New-FsrmAutoQuota` aplikowany jest gotowy szablon o nazwie "Quota limit for HOME". Gwarantuje to, że zasoby dyskowe serwera nie zostaną zapchane przez nowych użytkowników.
    

## Wymagania

-   Moduł `ActiveDirectory`.
    
-   Aktywna usługa WinRM (`Enable-PSRemoting`) na serwerze wskazanym w parametrze `$TargetFS`.
    
-   Zainstalowana i skonfigurowana rola **FSRM (File Server Resource Manager)** na docelowym serwerze plików, posiadająca szablon "Quota limit for HOME".
    

## Użycie

Wywołaj skrypt, definiując docelowy serwer plików i liczbę kont. Cały proces (wraz z nadaniem uprawnień i limitów dyskowych) wykona się błyskawicznie w ramach jednej operacji.

**Przykład wywołania:**

```powershell
.\New-ADAccounts.ps1 -Count 15 -TargetFS "vm01"
```

**Zastrzeżenie!** _Skrypt wprowadza zmiany w Active Directory. Mimo że został napisany z dbałością o błędy, używasz ich na własną odpowiedzialność! Przetestuj dokładnie jego działanie na środowisku testowym przed uruchomieniem go na produkcji :)_

Autor: _Kacper Walczuk **(@walczukk)**_ | _kacper@walcz.uk_ | _[walcz.uk](https://walcz.uk/)_
