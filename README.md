# 👤 New-ADAccounts (SysOps)

![PowerShell](https://img.shields.io/badge/PowerShell-5.1-blue?logo=powershell) ![Active Directory](https://img.shields.io/badge/ActiveDirectory-Module-green) ![v0.2](https://img.shields.io/badge/wersja-0.2-e45959)

To repozytorium zawiera zaktualizowaną wersję rozwiązania do zarządzania kontami w AD oraz ich zasobami plikowymi. Wersja 0.2 wprowadza przede wszystkim elastyczność dzięki parametryzacji głównego skryptu oraz nowy, lżejszy silnik nadawania uprawnień.

## Architektura rozwiązania

Rozwiązanie przeszło ewolucję w stronę większej uniwersalności i szybkości działania:

### 1. Parametryzacja i logika (AD)

Zamiast sztywno wpisanego kodu, skrypt zyskał pełną obsługę parametrów (CmdletBinding). Dzięki temu uruchamiający może zdefiniować w locie takie dane jak:

-   Prefiks użytkownika (`$UserPrefix`), sufiks domeny (`$DomainSuffix`), docelowe OU (`$TargetOU`) oraz grupy (`$TargetGroups`).
    
-   Liczbę nowych kont do wygenerowania za pomocą parametru `-Count`.
    
-   Zmienne te trafiają do pętli, która dynamicznie oblicza numerację na podstawie istniejących już kont w środowisku.
    

### 2. Silnik uprawnień (icacls)

Pomocniczy skrypt `Give-PermissionsToFolder.ps1` został przepisany, aby działał wydajniej.

-   Zrezygnowano z problematycznych i topornych poleceń `Get-Acl` oraz `Set-Acl`.
    
-   Wdrożono narzędzie wiersza poleceń `icacls`, uruchamiane bezpośrednio na docelowym serwerze plików z wykorzystaniem `Invoke-Command`.
    
-   Do przekazania zmiennych lokalnych (np. nazwy usera) do zdalnej sesji skryptu wykorzystano modyfikator zakresu `$using:`.
    

### 3. Udostępnianie zasobów (SMB)

Mechanizm zakładania udziałów sieciowych pozostał zintegrowany ze zdalnym wywołaniem, gdzie za pomocą `New-SmbShare` dla każdego folderu domowego powstaje automatycznie ukryty udział z pełnym dostępem na poziomie zasobu sieciowego ("Change" dla grupy "Wszyscy").

## Wymagania

-   Moduł `ActiveDirectory`.
    
-   Aktywna usługa WinRM (umożliwiająca wykonanie `Invoke-Command`) na docelowym serwerze plików.
    
-   Odpowiednio skonfigurowane grupy docelowe w Active Directory.
    

## Użycie

Wywołaj skrypt, korzystając z nowych parametrów, aby dostosować liczbę kont i struktury do bieżących potrzeb.

**Przykład wywołania:**

PowerShell

```
.\New-ADAccounts.ps1 -UserPrefix "user" -Count 10 -TargetGroups @("gg-group1","gg-group2")
```

**Zastrzeżenie!** _Skrypt wprowadza zmiany w Active Directory. Mimo że został napisany z dbałością o błędy, używasz ich na własną odpowiedzialność! Przetestuj dokładnie jego działanie na środowisku testowym przed uruchomieniem go na produkcji :)_

Autor: _Kacper Walczuk **(@walczukk)**_ | _kacper@walcz.uk_ | _[walcz.uk](https://walcz.uk/)_
