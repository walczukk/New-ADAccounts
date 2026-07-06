# 👤 New-ADAccounts (SysOps)

![PowerShell](https://img.shields.io/badge/PowerShell-5.1-blue?logo=powershell) ![Active Directory](https://img.shields.io/badge/ActiveDirectory-Module-green) ![v1.2](https://img.shields.io/badge/wersja-1.2-e45959)


To repozytorium zawiera zaawansowaną wersję rozwiązania do zautomatyzowanego tworzenia kont w Active Directory. Wersja 1.2 wprowadza dynamiczne zarządzanie docelowym serwerem plików oraz inteligentne mechanizmy radzenia sobie z problemami replikacji po stronie domeny.

## Architektura rozwiązania

Skrypt został zoptymalizowany pod kątem stabilności i działania w rozproszonym środowisku:

### 1. Weryfikacja środowiska (PSRemoting)

Zanim skrypt zacznie modyfikować Active Directory, wykonuje prewencyjny test połączenia.

-   Używając polecenia `Invoke-Command`, skrypt próbuje wykonać proste zapytanie na docelowym serwerze plików (`$TargetFS`).
    
-   Jeśli serwer nie ma włączonej funkcji zdalnego zarządzania (WinRM) lub nie odpowiada, skrypt rzuca błędem i przerywa działanie, zapobiegając utworzeniu "osieroconych" kont w AD bez folderów domowych.
    

### 2. Pełna parametryzacja serwera docelowego

Usunięto twarde powiązania z serwerem `vm01`.

-   Dodano parametr `$TargetFS`, który pozwala skierować tworzenie struktur katalogów na dowolny serwer plików w domenie.
    
-   Skrypty pomocnicze również przyjmują ten parametr, wykorzystując `Invoke-Command` z argumentem `-ArgumentList` do bezpiecznego przekazywania zmiennych do zdalnej sesji.
    

### 3. Obejście opóźnień replikacji AD (icacls Retry Logic)

Głównym problemem podczas tworzenia kont i błyskawicznego przypisywania uprawnień (ACL) był błąd 1332 (brak mapowania między nazwami kont a identyfikatorami zabezpieczeń).

-   W skrypcie `Give-PermissionsToFolder.ps1` zaimplementowano mechanizm pętli `do...while`.
    
-   W przypadku wystąpienia błędu z kodem 1332, skrypt usypia się na 3 sekundy i ponawia próbę nadania uprawnień (maksymalnie 5 iteracji), dając kontrolerom domeny czas na zreplikowanie nowego obiektu do serwera plików.
    

## Wymagania

-   Moduł `ActiveDirectory`.
    
-   Aktywna usługa WinRM (umożliwiająca wykonanie `Invoke-Command`) na serwerze wskazanym w parametrze `$TargetFS`.
    

## Użycie

Wywołaj skrypt z odpowiednimi parametrami, definiując docelowy serwer plików oraz liczbę kont do wygenerowania.

**Przykład wywołania:**

PowerShell

```
.\New-ADAccounts.ps1 -Count 2 -TargetFS "FileServer02"
```

**Zastrzeżenie!** _Skrypt wprowadza zmiany w Active Directory. Mimo że został napisany z dbałością o błędy, używasz ich na własną odpowiedzialność! Przetestuj dokładnie jego działanie na środowisku testowym przed uruchomieniem go na produkcji :)_

Autor: _Kacper Walczuk **(@walczukk)**_ | _kacper@walcz.uk_ | _[walcz.uk](https://walcz.uk/)_
