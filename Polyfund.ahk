/*
Script: Polyfund
Συγγραφέας: Tasos
Έτος: 2025
MIT License
Copyright (c) 2025 Tasos
*/
#Requires AutoHotkey v2.0+
#SingleInstance Force
#Warn All, OutputDebug
FileEncoding("UTF-16")

MAIN_PROGRAM() {
    ; Δημιουργία κενού Fund.ini αν δεν υπάρχει
    if !FileExist("Fund.ini") {
        try {
            FileAppend("", "Fund.ini", "UTF-16")
        } catch as e {
            MsgBox "Σφάλμα δημιουργίας Fund.ini: " e.Message
        }
    }

    ; Δηλώσεις global μεταβλητών
    global ExpensesLV, OwnersLV, NewCashEdit, BalanceText, CurrentCashEdit
    global Expenses, Apartments, General, CurrentCash, NewCash, SelectedApartment
    global SelectedText, InfoText, TotalExpensesText, ApartmentsText, MyGui
    global StatusBar, TotalDebtText

    ; Μεταβλητές
    Expenses := Map()
    Apartments := Map()
    General := Map()
    CurrentCash := 0
    NewCash := 0
    SelectedApartment := 0
    GlobalCursorPos := 0

    ; ═══════════════════════════════════════════════════════════
    ; ΒΟΗΘΗΤΙΚΕΣ ΣΥΝΑΡΤΗΣΕΙΣ
    ; ═══════════════════════════════════════════════════════════

    SaveCursorPosition(Ctrl, Info) {
        global GlobalCursorPos
        try {
            VarSetCapacity(start, 4, 0)
            VarSetCapacity(end, 4, 0)
            SendMessage(0x00B0, &start, &end, Ctrl.Hwnd)
            GlobalCursorPos := NumGet(start, 0, "UInt")
        } catch {
            GlobalCursorPos := 0
        }
    }

    LoadInitialData() {
        global Expenses, Apartments, General, CurrentCash
        Expenses := Map(
            "Clean", 0,
            "Electricity", 0,
            "Water", 0,
            "Fire", 0,
            "Gardener", 0,
            "Other", 0,
            "CommonTotal", 0,
            "Elevator", 0,
            "Heating", 0,
            "Printing", 0,
            "Reserve", 0
        )
        Apartments := Map()
        General := Map()
        CurrentCash := 0
    }

    LoadDataFromExpenses() {
        global Expenses, Apartments, General, CurrentCash, StatusBar
        Expenses := Map(
            "Clean", 0,
            "Electricity", 0,
            "Water", 0,
            "Fire", 0,
            "Gardener", 0,
            "Other", 0,
            "CommonTotal", 0,
            "Elevator", 0,
            "Heating", 0,
            "Printing", 0,
            "Reserve", 0
        )
        Apartments := Map()
        General := Map()
        CurrentCash := 0

        try {
            currentSection := ""
            loop read, "Expenses.ini" {
                line := Trim(A_LoopReadLine)
                if (line = "")
                    continue
                if (SubStr(line, 1, 1) = "[" && SubStr(line, -1) = "]") {
                    currentSection := SubStr(line, 2, StrLen(line) - 2)
                    continue
                }
                if (InStr(line, "=")) {
                    key := Trim(SubStr(line, 1, InStr(line, "=") - 1))
                    value := Trim(SubStr(line, InStr(line, "=") + 1))
                    if (currentSection = "General") {
                        if (key = "TotalExpenses" || key = "ApartmentCount") {
                            General[key] := Number(value)
                        } else if (key = "Date") {
                            General[key] := value
                        }
                    }
                    else if (currentSection = "Expenses") {
                        if (Expenses.Has(key))
                            Expenses[key] := Number(value)
                    }
                    else if (InStr(currentSection, "Apartment_")) {
                        aptNum := SubStr(currentSection, 11)
                        if (RegExMatch(aptNum, "^\d+$")) {
                            if (!Apartments.Has(aptNum))
                                Apartments[aptNum] := Map()
                            if (key = "Payment")
                                Apartments[aptNum][key] := Number(value)
                            else if (key = "Name" || key = "Owner")
                                Apartments[aptNum][key] := value
                        }
                    }
                }
            }
            StatusBar.SetText("✅ Δεδομένα φορτώθηκαν από Expenses.ini")
        } catch as e {
            StatusBar.SetText("❌ Σφάλμα ανάγνωσης Expenses.ini")
            MsgBox "Σφάλμα ανάγνωσης αρχείου Expenses.ini: " e.Message
        }
    }

    LoadDataFromFund() {
        global Expenses, Apartments, General, CurrentCash, StatusBar
        Expenses := Map(
            "Clean", 0,
            "Electricity", 0,
            "Water", 0,
            "Fire", 0,
            "Gardener", 0,
            "Other", 0,
            "CommonTotal", 0,
            "Elevator", 0,
            "Heating", 0,
            "Printing", 0,
            "Reserve", 0
        )
        Apartments := Map()
        General := Map()
        CurrentCash := 0

        ; Φόρτωση από Expenses.ini
        try {
            currentSection := ""
            loop read, "Expenses.ini" {
                line := Trim(A_LoopReadLine)
                if (line = "")
                    continue
                if (SubStr(line, 1, 1) = "[" && SubStr(line, -1) = "]") {
                    currentSection := SubStr(line, 2, StrLen(line) - 2)
                    continue
                }
                if (InStr(line, "=")) {
                    key := Trim(SubStr(line, 1, InStr(line, "=") - 1))
                    value := Trim(SubStr(line, InStr(line, "=") + 1))
                    if (currentSection = "General") {
                        if (key = "TotalExpenses" || key = "ApartmentCount")
                            General[key] := Number(value)
                        else if (key = "Date")
                            General[key] := value
                    }
                    else if (currentSection = "Expenses") {
                        if (Expenses.Has(key))
                            Expenses[key] := Number(value)
                    }
                }
            }
        } catch as e {
            StatusBar.SetText("❌ Σφάλμα ανάγνωσης Expenses.ini")
            MsgBox "Σφάλμα ανάγνωσης αρχείου Expenses.ini: " e.Message
        }

        ; Φόρτωση από Fund.ini
        if (FileExist("Fund.ini")) {
            try {
                currentSection := ""
                loop read, "Fund.ini" {
                    line := Trim(A_LoopReadLine)
                    if (line = "")
                        continue
                    if (SubStr(line, 1, 1) = "[" && SubStr(line, -1) = "]") {
                        currentSection := SubStr(line, 2, StrLen(line) - 2)
                        continue
                    }
                    if (InStr(line, "=")) {
                        key := Trim(SubStr(line, 1, InStr(line, "=") - 1))
                        value := Trim(SubStr(line, InStr(line, "=") + 1))
                        if (currentSection = "General") {
                            if (key = "CurrentCash")
                                CurrentCash := Number(value)
                            else if (key = "Date" || key = "TotalExpenses" || key = "ApartmentCount")
                                General[key] := (key = "Date") ? value : Number(value)
                        }
                        else if (currentSection = "Apartments") {
                            if (InStr(key, "_")) {
                                aptName := SubStr(key, 1, InStr(key, "_") - 1)
                                ownerName := SubStr(key, InStr(key, "_") + 1)
                                debt := Number(value)
                                aptKey := aptName
                                Apartments[aptKey] := Map()
                                Apartments[aptKey]["Name"] := aptName
                                Apartments[aptKey]["Owner"] := ownerName
                                Apartments[aptKey]["Payment"] := debt
                            }
                        }
                    }
                }
                StatusBar.SetText("✅ Δεδομένα φορτώθηκαν από Expenses.ini και Fund.ini")
            } catch as e {
                StatusBar.SetText("❌ Σφάλμα ανάγνωσης Fund.ini")
                MsgBox "Σφάλμα ανάγνωσης αρχείου Fund.ini: " e.Message
            }
        }
    }

    UpdateExpensesList() {
        global ExpensesLV, Expenses, General
        ExpenseTranslations := Map(
            "Clean", "💧 Καθαριότητα",
            "Electricity", "⚡ Ρεύμα",
            "Water", "🚰 Νερό",
            "Fire", "🔥 Πυρασφάλεια",
            "Gardener", "🌳 Κηπουρός",
            "Other", "💼 Άλλα",
            "CommonTotal", "📊 Σύνολο Κοινοχρήστων",
            "Elevator", "🛗 Ανελκυστήρας",
            "Heating", "🔥 Θέρμανση",
            "Printing", "🖨️ Εκτύπωση",
            "Reserve", "💰 Αποθεματικό"
        )
        ExpenseOrder := ["Clean", "Electricity", "Water", "Fire", "Gardener", "Other", "Elevator", "Heating", "Printing", "Reserve"]

        ExpensesLV.Delete()
        Loop ExpenseOrder.Length {
            category := ExpenseOrder[A_Index]
            if (Expenses.Has(category) && Expenses[category] > 0) {
                greekCategory := ExpenseTranslations.Has(category) ? ExpenseTranslations[category] : category
                ExpensesLV.Add("", greekCategory, Format("{:0.2f} €", Expenses[category]))
            }
        }
        if (General.Has("TotalExpenses"))
            ExpensesLV.Add("", "💵 ΣΥΝΟΛΟ", Format("{:0.2f} €", General["TotalExpenses"]))
    }

    UpdateOwnersList() {
        global OwnersLV, Apartments
        OwnersLV.Delete()
        for aptKey, apartmentData in Apartments {
            if (IsObject(apartmentData) && apartmentData.Has("Owner") && apartmentData.Has("Name") && apartmentData.Has("Payment")) {
                OwnersLV.Add("", apartmentData["Owner"], apartmentData["Name"], 
                    Format("{:0.2f} €", apartmentData["Payment"]))
            }
        }
    }

    SelectApartment(LV, Row) {
        global SelectedApartment, SelectedText, Apartments
        if (Row > 0) {
            OwnerName := LV.GetText(Row, 1)
            ApartmentName := LV.GetText(Row, 2)
            SelectedApartment := 0
            for aptNum, apartmentData in Apartments {
                if (apartmentData["Owner"] = OwnerName && apartmentData["Name"] = ApartmentName) {
                    SelectedApartment := aptNum
                    break
                }
            }
            if (SelectedApartment != 0) {
                apartmentData := Apartments[SelectedApartment]
                SelectedText.Text := "🏠 " . apartmentData["Name"] . "`n👤 " . apartmentData["Owner"]
            }
        }
    }

    ValidateCurrentCashInput(Ctrl, Info) {
        global CurrentCash, GlobalCursorPos
        try {
            VarSetCapacity(start, 4, 0)
            VarSetCapacity(end, 4, 0)
            SendMessage(0x00B0, &start, &end, Ctrl.Hwnd)
            currentPos := NumGet(start, 0, "UInt")
            if (currentPos > 0)
                GlobalCursorPos := currentPos
        } catch {
            GlobalCursorPos := 0
        }
        currentValue := Ctrl.Value
        validatedValue := ValidateNumberString(currentValue)
        if (validatedValue != currentValue) {
            Ctrl.Value := validatedValue
            if (GlobalCursorPos > 0) {
                Sleep(10)
                SendMessage(0x00B1, GlobalCursorPos, GlobalCursorPos, Ctrl.Hwnd)
            }
        }
        CurrentCash := Number(validatedValue)
        UpdateBalance()
    }

    ValidateNumberString(inputString) {
        cleanedString := RegExReplace(inputString, "[^\d,.]", "")
        cleanedString := StrReplace(cleanedString, ",", ".")
        if (RegExMatch(cleanedString, "^\d*\.?\d*$") = 0) {
            dotPos := InStr(cleanedString, ".")
            if (dotPos > 0) {
                beforeDot := SubStr(cleanedString, 1, dotPos)
                afterDot := RegExReplace(SubStr(cleanedString, dotPos + 1), "[^\d]", "")
                cleanedString := beforeDot . afterDot
            }
        }
        if (cleanedString = "" || cleanedString = ".")
            return "0.00"
        numberValue := Number(cleanedString)
        if (numberValue = "")
            return "0.00"
        return Format("{:0.2f}", numberValue)
    }

    UpdateBalance() {
        global BalanceText, Apartments, CurrentCash, NewCash, NewCashEdit, TotalDebtText
        totalDebt := 0
        for aptNum, apartmentData in Apartments {
            if (apartmentData.Has("Payment"))
                totalDebt += apartmentData["Payment"]
        }
        totalNewCash := CurrentCash + NewCash
        NewCashEdit.Value := Format("{:0.2f}", totalNewCash)
        BalanceText.Text := Format("{:0.2f} €", totalDebt)
        TotalDebtText.Value := Format("{:0.2f} €", totalDebt)
    }

    PayFull(*) {
        global SelectedApartment, Apartments, NewCash, StatusBar
        if (SelectedApartment = 0) {
            MsgBox "Παρακαλώ επιλέξτε πρώτα ένα διαμέρισμα από τη λίστα", "Προσοχή", "Icon!"
            return
        }
        if (!Apartments.Has(SelectedApartment)) {
            MsgBox "Δεν βρέθηκαν δεδομένα για το επιλεγμένο διαμέρισμα", "Σφάλμα", "Icon!"
            return
        }
        apartmentData := Apartments[SelectedApartment]
        if (!apartmentData.Has("Payment")) {
            MsgBox "Δεν βρέθηκαν δεδομένα πληρωμής για το διαμέρισμα", "Σφάλμα", "Icon!"
            return
        }
        amount := apartmentData["Payment"]
        if (amount > 0) {
            Apartments[SelectedApartment]["Payment"] := 0
            NewCash += amount
            UpdateOwnersList()
            UpdateBalance()
            StatusBar.SetText("✅ Εξόφληση: " . Format("{:0.2f} €", amount))
            MsgBox "Εξόφληση " Format("{:0.2f} €", amount) " για " apartmentData["Owner"] . " (" . apartmentData["Name"] . ")", "Επιτυχής Εξόφληση", "Iconi"
        } else {
            MsgBox "Δεν υπάρχει χρέος για εξόφληση", "Πληροφορία", "Iconi"
        }
    }

    PayPartial(*) {
        global SelectedApartment, Apartments, NewCash, StatusBar
        if (SelectedApartment = 0) {
            MsgBox "Παρακαλώ επιλέξτε πρώτα ένα διαμέρισμα από τη λίστα", "Προσοχή", "Icon!"
            return
        }
        if (!Apartments.Has(SelectedApartment)) {
            MsgBox "Δεν βρέθηκαν δεδομένα για το επιλεγμένο διαμέρισμα", "Σφάλμα", "Icon!"
            return
        }
        apartmentData := Apartments[SelectedApartment]
        if (!apartmentData.Has("Payment")) {
            MsgBox "Δεν βρέθηκαν δεδομένα πληρωμής για το διαμέρισμα", "Σφάλμα", "Icon!"
            return
        }
        currentDebt := apartmentData["Payment"]
        if (currentDebt > 0) {
            PartialPayGui := Gui("+ToolWindow +AlwaysOnTop", "💰 Μερική Εξόφληση")
            PartialPayGui.OnEvent("Close", (*) => PartialPayGui.Destroy())
            PartialPayGui.SetFont("s10", "Segoe UI")
            PartialPayGui.BackColor := "0xF0F0F0"
            PartialPayGui.MarginX := 20
            PartialPayGui.MarginY := 15

            PartialPayGui.SetFont("s11 Bold", "Segoe UI")
            PartialPayGui.Add("Text", "w400 Center c0x1565C0 Background0xE3F2FD", "ΜΕΡΙΚΗ ΕΞΟΦΛΗΣΗ")
            PartialPayGui.SetFont("s10 Norm", "Segoe UI")
            
            InfoGroup := PartialPayGui.Add("GroupBox", "x10 y40 w400 h120", "Στοιχεία Διαμερίσματος")
            InfoGroup.SetFont("s10 Bold")
            PartialPayGui.SetFont("s9 Norm")
            
            PartialPayGui.Add("Text", "x20 y65 w180", "🏠 Διαμέρισμα:")
            PartialPayGui.Add("Text", "x200 y65 w200 c0x1565C0", apartmentData["Name"])
            PartialPayGui.Add("Text", "x20 y90 w180", "👤 Ιδιοκτήτης:")
            PartialPayGui.Add("Text", "x200 y90 w200 c0x1565C0", apartmentData["Owner"])
            PartialPayGui.Add("Text", "x20 y115 w180", "💳 Υπόλοιπο χρέους:")
            DebtText := PartialPayGui.Add("Text", "x200 y115 w200 cRed", Format("{:0.2f} €", currentDebt))
            DebtText.SetFont("s10 Bold")

            PayGroup := PartialPayGui.Add("GroupBox", "x10 y170 w400 h80", "Ποσό Εξόφλησης")
            PayGroup.SetFont("s10 Bold")
            PartialPayGui.SetFont("s9 Norm")
            
            PartialPayGui.Add("Text", "x20 y195 w180", "💵 Ποσό προς πληρωμή:")
            AmountEdit := PartialPayGui.Add("Edit", "x200 y192 w190 h30 Center Background0xFFFFFF", Format("{:0.2f}", currentDebt))
            AmountEdit.SetFont("s11 Bold", "Segoe UI")

            PartialPayGui.SetFont("s10 Bold")
            OKBtn := PartialPayGui.Add("Button", "x10 y265 w195 h45 Default", "✅ ΕΞΟΦΛΗΣΗ")
            CancelBtn := PartialPayGui.Add("Button", "x215 y265 w195 h45", "❌ ΑΚΥΡΩΣΗ")

            ValidateAmount(*) {
                validatedAmount := ValidateNumberString(AmountEdit.Value)
                if (validatedAmount != AmountEdit.Value)
                    AmountEdit.Value := validatedAmount
                amount := Number(validatedAmount)
                if (amount > currentDebt)
                    AmountEdit.Value := Format("{:0.2f}", currentDebt)
            }

            AmountEdit.OnEvent("Change", ValidateAmount)
            OKBtn.OnEvent("Click", OK_Click)
            CancelBtn.OnEvent("Click", (*) => PartialPayGui.Destroy())

            OK_Click(*) {
                validatedAmount := ValidateNumberString(AmountEdit.Value)
                if (validatedAmount = "" || validatedAmount = "0.00") {
                    MsgBox "Παρακαλώ εισάγετε έγκυρο αριθμό (π.χ. 50,50 ή 50.50)", "Προσοχή", "Icon!"
                    return
                }
                amount := Number(validatedAmount)
                if (amount <= 0) {
                    MsgBox "Το ποσό πρέπει να είναι μεγαλύτερο από 0", "Προσοχή", "Icon!"
                    return
                }
                if (amount > currentDebt) {
                    MsgBox "Το ποσό υπερβαίνει το χρέος. Μέγιστο επιτρεπτό: " Format("{:0.2f} €", currentDebt), "Προσοχή", "Icon!"
                    return
                }
                Apartments[SelectedApartment]["Payment"] := currentDebt - amount
                NewCash += amount
                UpdateOwnersList()
                UpdateBalance()
                StatusBar.SetText("✅ Μερική εξόφληση: " . Format("{:0.2f} €", amount))
                PartialPayGui.Destroy()
                MsgBox "Μερική εξόφληση " Format("{:0.2f} €", amount) " για " apartmentData["Owner"] . " (" . apartmentData["Name"] . ")`nΥπόλοιπο χρέους: " Format("{:0.2f} €", currentDebt - amount), "Επιτυχής Πληρωμή", "Iconi"
            }

            PartialPayGui.Show("w430 h320 Center")
            AmountEdit.Focus()
            Send("{Home}+{End}")
        } else {
            MsgBox "Δεν υπάρχει χρέος για εξόφληση", "Πληροφορία", "Iconi"
        }
    }

    LoadExpenses(*) {
        global ExpensesLV, OwnersLV, InfoText, TotalExpensesText, ApartmentsText
        global CurrentCashEdit, NewCashEdit, CurrentCash, NewCash, SelectedApartment, SelectedText, StatusBar
        LoadDataFromExpenses()
        CurrentCashEdit.Value := Format("{:0.2f}", CurrentCash)
        NewCashEdit.Value := "0.00"
        NewCash := 0
        SelectedApartment := 0
        SelectedText.Text := "Επιλέξτε`nδιαμέρισμα"
        UpdateExpensesList()
        UpdateOwnersList()
        InfoText.Text := (General.Has("Date") ? General["Date"] : "N/A")
        TotalExpensesText.Text := Format("{:0.2f} €", General.Has("TotalExpenses") ? General["TotalExpenses"] : 0)
        ApartmentsText.Text := (General.Has("ApartmentCount") ? General["ApartmentCount"] : 0)
        UpdateBalance()
        StatusBar.SetText("✅ Δεδομένα φορτώθηκαν από Expenses.ini")
        MsgBox "Τα δεδομένα φορτώθηκαν επιτυχώς από το Expenses.ini!", "Επιτυχής Φόρτωση", "Iconi"
    }

    LoadFund(*) {
        global ExpensesLV, OwnersLV, InfoText, TotalExpensesText, ApartmentsText
        global CurrentCashEdit, NewCashEdit, CurrentCash, NewCash, SelectedApartment, SelectedText, StatusBar
        LoadDataFromFund()
        CurrentCashEdit.Value := Format("{:0.2f}", CurrentCash)
        NewCashEdit.Value := "0.00"
        NewCash := 0
        SelectedApartment := 0
        SelectedText.Text := "Επιλέξτε`nδιαμέρισμα"
        UpdateExpensesList()
        UpdateOwnersList()
        InfoText.Text := (General.Has("Date") ? General["Date"] : "N/A")
        TotalExpensesText.Text := Format("{:0.2f} €", General.Has("TotalExpenses") ? General["TotalExpenses"] : 0)
        ApartmentsText.Text := (General.Has("ApartmentCount") ? General["ApartmentCount"] : 0)
        UpdateBalance()
        StatusBar.SetText("✅ Δεδομένα φορτώθηκαν από Expenses.ini και Fund.ini")
        MsgBox "Τα δεδομένα φορτώθηκαν επιτυχώς από τα αρχεία Expenses.ini και Fund.ini!", "Επιτυχής Φόρτωση", "Iconi"
    }

    SaveData(*) {
        global Apartments, CurrentCash, NewCash, CurrentCashEdit, NewCashEdit, General, StatusBar
        CurrentCash += NewCash
        CurrentCashEdit.Value := Format("{:0.2f}", CurrentCash)
        NewCash := 0
        NewCashEdit.Value := "0.00"

        try {
            fundContent := ""
            fundContent .= "[General]`r`n"
            fundContent .= "Date=" . (General.Has("Date") ? General["Date"] : "N/A") . "`r`n"
            fundContent .= "TotalExpenses=" . (General.Has("TotalExpenses") ? Format("{:0.2f}", General["TotalExpenses"]) : "0.00") . "`r`n"
            fundContent .= "ApartmentCount=" . (General.Has("ApartmentCount") ? General["ApartmentCount"] : "0") . "`r`n"
            fundContent .= "CurrentCash=" . Format("{:0.2f}", CurrentCash) . "`r`n"
            fundContent .= "`r`n"
            fundContent .= "[Apartments]`r`n"
            
            totalDebt := 0
            for aptKey, apartmentData in Apartments {
                if (IsObject(apartmentData) && apartmentData.Has("Owner") && apartmentData.Has("Name") && apartmentData.Has("Payment")) {
                    debt := apartmentData["Payment"]
                    totalDebt += debt
                    fundContent .= apartmentData["Name"] . "_" . apartmentData["Owner"] . "=" . Format("{:0.2f}", debt) . "`r`n"
                }
            }
            
            fundContent .= "`r`n"
            fundContent .= "[Summary]`r`n"
            fundContent .= "TotalDebt=" . Format("{:0.2f}", totalDebt) . "`r`n"
            totalExpenses := General.Has("TotalExpenses") ? General["TotalExpenses"] : 0
            balance := CurrentCash + totalDebt
            fundContent .= "Balance=" . Format("{:0.2f}", balance) . "`r`n"
            
            FileDelete("Fund.ini")
            FileAppend(fundContent, "Fund.ini", "UTF-16")
            
            StatusBar.SetText("✅ Αποθήκευση επιτυχής | Ταμείο: " . Format("{:0.2f} €", CurrentCash))
            MsgBox "Τα δεδομένα αποθηκεύτηκαν επιτυχώς στο Fund.ini!`n`nΝέο ταμείο: " Format("{:0.2f} €", CurrentCash) . "`nΣυνολικά χρωστουμένα: " Format("{:0.2f} €", totalDebt), "Επιτυχής Αποθήκευση", "Iconi"
            UpdateBalance()
        } catch as e {
            StatusBar.SetText("❌ Σφάλμα αποθήκευσης!")
            MsgBox "Σφάλμα αποθήκευσης: " e.Message, "Σφάλμα", "Icon!"
        }
    }

    NewMonth(*) {
        global Expenses, Apartments, General, CurrentCash, CurrentCashEdit, NewCash
        global SelectedApartment, SelectedText, InfoText, TotalExpensesText, ApartmentsText, StatusBar

        tempExpenses := Map()
        tempApartments := Map()
        tempGeneral := Map()

        try {
            currentSection := ""
            loop read, "Expenses.ini" {
                line := Trim(A_LoopReadLine)
                if (line = "")
                    continue
                if (SubStr(line, 1, 1) = "[" && SubStr(line, -1) = "]") {
                    currentSection := SubStr(line, 2, StrLen(line) - 2)
                    continue
                }
                if (InStr(line, "=")) {
                    key := Trim(SubStr(line, 1, InStr(line, "=") - 1))
                    value := Trim(SubStr(line, InStr(line, "=") + 1))
                    if (currentSection = "General") {
                        if (key = "TotalExpenses" || key = "ApartmentCount")
                            tempGeneral[key] := Number(value)
                        else if (key = "Date")
                            tempGeneral[key] := value
                    }
                    else if (currentSection = "Expenses") {
                        tempExpenses[key] := Number(value)
                    }
                    else if (InStr(currentSection, "Apartment_")) {
                        aptNum := SubStr(currentSection, 11)
                        if (RegExMatch(aptNum, "^\d+$")) {
                            if (!tempApartments.Has(aptNum))
                                tempApartments[aptNum] := Map()
                            if (key = "Payment")
                                tempApartments[aptNum][key] := Number(value)
                            else if (key = "Name" || key = "Owner")
                                tempApartments[aptNum][key] := value
                        }
                    }
                }
            }
        } catch as e {
            StatusBar.SetText("❌ Σφάλμα ανάγνωσης Expenses.ini")
            MsgBox "Σφάλμα ανάγνωσης αρχείου Expenses.ini: " e.Message, "Σφάλμα", "Icon!"
            return
        }

        tempFundApartments := Map()
        tempFundCash := 0
        if (FileExist("Fund.ini")) {
            try {
                currentSection := ""
                loop read, "Fund.ini" {
                    line := Trim(A_LoopReadLine)
                    if (line = "")
                        continue
                    if (SubStr(line, 1, 1) = "[" && SubStr(line, -1) = "]") {
                        currentSection := SubStr(line, 2, StrLen(line) - 2)
                        continue
                    }
                    if (InStr(line, "=")) {
                        key := Trim(SubStr(line, 1, InStr(line, "=") - 1))
                        value := Trim(SubStr(line, InStr(line, "=") + 1))
                        if (currentSection = "General") {
                            if (key = "CurrentCash")
                                tempFundCash := Number(value)
                        }
                        else if (currentSection = "Apartments") {
                            if (InStr(key, "_")) {
                                aptName := SubStr(key, 1, InStr(key, "_") - 1)
                                ownerName := SubStr(key, InStr(key, "_") + 1)
                                debt := Number(value)
                                for aptNum, aptData in tempApartments {
                                    if (aptData["Name"] = aptName && aptData["Owner"] = ownerName) {
                                        if (!tempFundApartments.Has(aptNum))
                                            tempFundApartments[aptNum] := Map()
                                        tempFundApartments[aptNum]["Name"] := aptName
                                        tempFundApartments[aptNum]["Owner"] := ownerName
                                        tempFundApartments[aptNum]["Payment"] := debt
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
            } catch as e {
                StatusBar.SetText("❌ Σφάλμα ανάγνωσης Fund.ini")
                MsgBox "Σφάλμα ανάγνωσης αρχείου Fund.ini: " e.Message, "Σφάλμα", "Icon!"
                return
            }
        }

        totalExpensesFromFile := tempGeneral.Has("TotalExpenses") ? tempGeneral["TotalExpenses"] : 0
        newCashBalance := tempFundCash - totalExpensesFromFile

        for aptNum, fundAptData in tempFundApartments {
            if (tempApartments.Has(aptNum))
                tempApartments[aptNum]["Payment"] += fundAptData["Payment"]
            else {
                tempApartments[aptNum] := Map()
                tempApartments[aptNum]["Name"] := fundAptData["Name"]
                tempApartments[aptNum]["Owner"] := fundAptData["Owner"]
                tempApartments[aptNum]["Payment"] := fundAptData["Payment"]
            }
        }

        Expenses := tempExpenses
        Apartments := tempApartments
        General := tempGeneral
        CurrentCash := newCashBalance

        CurrentCashEdit.Value := Format("{:0.2f}", CurrentCash)
        NewCash := 0
        SelectedApartment := 0
        SelectedText.Text := "Επιλέξτε`nδιαμέρισμα"
        UpdateExpensesList()
        UpdateOwnersList()
        InfoText.Text := (General.Has("Date") ? General["Date"] : "N/A")
        TotalExpensesText.Text := Format("{:0.2f} €", General.Has("TotalExpenses") ? General["TotalExpenses"] : 0)
        ApartmentsText.Text := (General.Has("ApartmentCount") ? General["ApartmentCount"] : 0)
        UpdateBalance()
        
        StatusBar.SetText("✅ Νέος μήνας | Ταμείο: " . Format("{:0.2f} €", CurrentCash))
        MsgBox "Νέος μήνας δημιουργήθηκε επιτυχώς!`n`nΝέο ταμείο: " Format("{:0.2f} €", CurrentCash) . "`n(Ταμείο Fund.ini - Σύνολο εξόδων Expenses.ini)", "Νέος Μήνας", "Iconi"
    }

    GuiClose(*) {
        ExitApp
    }

    ShowInstructions(*) {
        instructionsText := ""
        instructionsText .= "═══════════════════════════════════════════════════`n"
        instructionsText .= "            ΟΔΗΓΙΕΣ ΧΡΗΣΗΣ - POLYFUND`n"
        instructionsText .= "═══════════════════════════════════════════════════`n`n"
        instructionsText .= "📂 ΦΟΡΤΩΣΗ ΔΕΔΟΜΕΝΩΝ:`n"
        instructionsText .= "   • POLYCALC INI: Φορτώνει νέα δεδομένα από Polycalc`n"
        instructionsText .= "   • ΤΡΕΧΩΝ ΜΗΝΑΣ: Φορτώνει τα τρέχοντα δεδομένα`n"
        instructionsText .= "   • ΝΕΟΣ ΜΗΝΑΣ: Δημιουργεί νέο μήνα με υπολογισμούς`n`n"
        instructionsText .= "💳 ΕΞΟΦΛΗΣΕΙΣ:`n"
        instructionsText .= "   1. Επιλέξτε διαμέρισμα από τη λίστα`n"
        instructionsText .= "   2. Πατήστε 'ΠΛΗΡΗΣ ΕΞΟΦΛΗΣΗ' ή 'ΜΕΡΙΚΗ ΕΞΟΦΛΗΣΗ'`n"
        instructionsText .= "   3. Το ποσό θα προστεθεί στο νέο ταμείο`n`n"
        instructionsText .= "💾 ΑΠΟΘΗΚΕΥΣΗ:`n"
        instructionsText .= "   • Πατήστε 'ΑΠΟΘΗΚΕΥΣΗ' για να σώσετε τις αλλαγές`n"
        instructionsText .= "   • Το νέο ταμείο θα προστεθεί στο υπάρχον`n`n"
        instructionsText .= "💡 ΣΗΜΕΙΩΣΕΙΣ:`n"
        instructionsText .= "   • Όλοι οι υπολογισμοί γίνονται αυτόματα`n"
        instructionsText .= "   • Τα χρέη μεταφέρονται από μήνα σε μήνα`n"
        instructionsText .= "   • Το ταμείο υπολογίζεται: Παλιό - Έξοδα + Εισπράξεις`n"
        instructionsText .= "═══════════════════════════════════════════════════"
        MsgBox(instructionsText, "Οδηγίες Χρήσης", 64)
    }

    ShowInfo(*) {
        infoText := ""
        infoText .= "═══════════════════════════════════════════════════`n"
        infoText .= "                    Polyfund`n"
        infoText .= "═══════════════════════════════════════════════════`n`n"
        infoText .= "Έκδοση: v1.0`n"
        infoText .= "Δημιουργός: Tasos`n"
        infoText .= "Ημερομηνία Έκδοσης: 27/09/2025`n"
        infoText .= "Τελευταία Ενημέρωση: 23/10/2025`n`n"
        infoText .= "Email: maxiths1984@gmail.com`n`n"
        infoText .= "═══════════════════════════════════════════════════`n"
        infoText .= "© 2025 Όλα τα δικαιώματα διατηρούνται`n"
        infoText .= "═══════════════════════════════════════════════════"
        MsgBox(infoText, "Πληροφορίες Προγράμματος", 64)
    }

    ; ═══════════════════════════════════════════════════════════
    ; ΔΗΜΙΟΥΡΓΙΑ GUI
    ; ═══════════════════════════════════════════════════════════

    LoadInitialData()

    TraySetIcon("Shell32.dll", 44)
    MyGui := Gui(, "Polyfund")
    MyGui.OnEvent("Close", GuiClose)
    MyGui.OnEvent("Escape", GuiClose)
    MyGui.SetFont("s10", "Segoe UI")
    MyGui.BackColor := "0xF0F0F0"
    MyGui.Opt("-Resize +MaximizeBox +MinimizeBox")

    ; Status Bar
    StatusBar := MyGui.AddStatusBar(, "Έτοιμο | Έκδοση: v1.0")

    ; ═══ ΤΙΤΛΟΣ ═══
    MyGui.SetFont("s12 Bold", "Segoe UI")
    MyGui.Add("Text", "x10 y10 w1080 h35 Center c0x2C5F2D BackgroundWhite", "💰 ΔΙΑΧΕΙΡΙΣΗ ΤΑΜΕΙΟΥ & ΧΡΕΩΝ ΠΟΛΥΚΑΤΟΙΚΙΑΣ")
    MyGui.SetFont("s10 Norm", "Segoe UI")

    ; ═══ ΑΡΙΣΤΕΡΗ ΣΤΗΛΗ - ΕΞΟΔΑ (Πάνω) ═══
    ExpensesGroup := MyGui.AddGroupBox("x10 y55 w340 h280", "📊 ΕΞΟΔΑ ΜΗΝΑ")
    ExpensesGroup.SetFont("s10 Bold")
    MyGui.SetFont("s9 Norm")
    
    ExpensesLV := MyGui.AddListView("x20 y75 w320 h250 Background0xFFFFFF Grid", ["Κατηγορία", "Ποσό"])
    ExpensesLV.ModifyCol(1, 200)
    ExpensesLV.ModifyCol(2, 100)

    ; ═══ ΑΡΙΣΤΕΡΗ ΣΤΗΛΗ - ΠΛΗΡΟΦΟΡΙΕΣ & ΤΑΜΕΙΟ (Κάτω) ═══
    InfoGroup := MyGui.AddGroupBox("x10 y345 w340 h250", "📋 ΠΛΗΡΟΦΟΡΙΕΣ & ΤΑΜΕΙΟ")
    InfoGroup.SetFont("s10 Bold")
    MyGui.SetFont("s9 Norm")

    ; Πληροφορίες
    MyGui.Add("Text", "x20 y370 w130 h20", "📅 Ημερομηνία:")
    InfoText := MyGui.Add("Text", "x150 y370 w180 h20 c0x1565C0", "N/A")
    
    MyGui.Add("Text", "x20 y395 w130 h20", "💵 Σύνολο Εξόδων:")
    TotalExpensesText := MyGui.Add("Text", "x150 y395 w180 h20 cRed", "0.00 €")
    TotalExpensesText.SetFont("s9 Bold")
    
    MyGui.Add("Text", "x20 y420 w130 h20", "🏢 Διαμερίσματα:")
    ApartmentsText := MyGui.Add("Text", "x150 y420 w180 h20 c0x2E7D32", "0")
    ApartmentsText.SetFont("s9 Bold")

    MyGui.Add("Text", "x20 y450 w310 h2 0x10")

    ; ΤΑΜΕΙΟ
    MyGui.SetFont("s9 Norm")
    MyGui.Add("Text", "x20 y465 w120 h25 Background0xE8F5E9", "💵 Υπάρχον:")
    CurrentCashEdit := MyGui.Add("Edit", "x145 y462 w175 h28 Background0xFFFFFF Center", Format("{:0.2f}", CurrentCash))
    CurrentCashEdit.SetFont("s10 Bold c0x1B5E20")
    CurrentCashEdit.OnEvent("Change", ValidateCurrentCashInput)
    CurrentCashEdit.OnEvent("Focus", SaveCursorPosition)

    MyGui.Add("Text", "x20 y500 w120 h25 Background0xE3F2FD", "💰 Νέο:")
    NewCashEdit := MyGui.Add("Edit", "x145 y497 w175 h28 ReadOnly Background0xC8E6C9 Center", "0.00")
    NewCashEdit.SetFont("s10 Bold c0x2E7D32")

    MyGui.Add("Text", "x20 y535 w120 h25 Background0xFFF3E0", "📊 Χρωστούμενα:")
    BalanceText := MyGui.Add("Edit", "x145 y532 w175 h28 ReadOnly Background0xFFEBEE Center", "0.00 €")
    BalanceText.SetFont("s10 Bold cRed")

    MyGui.Add("Text", "x20 y570 w120 h25 Background0xE3F2FD", "💵 Σύνολο Χρεών:")
    TotalDebtText := MyGui.Add("Edit", "x145 y567 w175 h28 ReadOnly Background0xFFCDD2 Center", "0.00 €")
    TotalDebtText.SetFont("s10 Bold cRed")

    ; ═══ ΜΕΣΗ ΣΤΗΛΗ - ΙΔΙΟΚΤΗΤΕΣ & ΧΡΕΗ ═══
    OwnersGroup := MyGui.AddGroupBox("x360 y55 w450 h540", "👥 ΙΔΙΟΚΤΗΤΕΣ & ΧΡΕΗ")
    OwnersGroup.SetFont("s10 Bold")
    MyGui.SetFont("s9 Norm")
    
    OwnersLV := MyGui.AddListView("x370 y75 w430 h510 Background0xFFFFFF Grid", ["Ονοματεπώνυμο", "Διαμ.", "Πληρωμή"])
    OwnersLV.ModifyCol(1, 200)
    OwnersLV.ModifyCol(2, 90)
    OwnersLV.ModifyCol(3, 120)
    OwnersLV.OnEvent("Click", SelectApartment)

    ; ═══ ΔΕΞΙΑ ΣΤΗΛΗ - ΕΝΕΡΓΕΙΕΣ ═══
    ActionsGroup := MyGui.AddGroupBox("x820 y55 w270 h540", "⚡ ΕΝΕΡΓΕΙΕΣ")
    ActionsGroup.SetFont("s10 Bold")
    MyGui.SetFont("s9 Bold")

    ; Επιλεγμένο διαμέρισμα
    SelectedGroup := MyGui.Add("GroupBox", "x830 y75 w250 h100", "Επιλεγμένο Διαμέρισμα")
    SelectedGroup.SetFont("s9 Bold")
    MyGui.SetFont("s8 Norm")
    SelectedText := MyGui.Add("Text", "x835 y95 w240 h70 Center Background0xFFF9C4", "Επιλέξτε διαμέρισμα`nαπό τη λίστα")

    ; Κουμπιά εξόφλησης
    MyGui.SetFont("s9 Bold")
    PayFullBtn := MyGui.Add("Button", "x830 y185 w250 h45", "✅ ΠΛΗΡΗΣ ΕΞΟΦΛΗΣΗ")
    PayFullBtn.OnEvent("Click", PayFull)
    
    PayPartialBtn := MyGui.Add("Button", "x830 y240 w250 h45", "💳 ΜΕΡΙΚΗ ΕΞΟΦΛΗΣΗ")
    PayPartialBtn.OnEvent("Click", PayPartial)

    ; ═══ ΚΟΥΜΠΙΑ ΔΙΑΧΕΙΡΙΣΗΣ ═══
    ButtonsGroup := MyGui.AddGroupBox("x10 y605 w1080 h70", "")
    
    MyGui.SetFont("s9 Bold")
    LoadExpensesBtn := MyGui.Add("Button", "x20 y620 w155 h45", "📂 POLYCALC INI")
    LoadExpensesBtn.OnEvent("Click", LoadExpenses)
    
    LoadFundBtn := MyGui.Add("Button", "x185 y620 w155 h45", "📅 ΤΡΕΧΩΝ ΜΗΝΑΣ")
    LoadFundBtn.OnEvent("Click", LoadFund)
    
    NewMonthBtn := MyGui.Add("Button", "x350 y620 w155 h45", "🗓️ ΝΕΟΣ ΜΗΝΑΣ")
    NewMonthBtn.OnEvent("Click", NewMonth)
    
    SaveBtn := MyGui.Add("Button", "x515 y620 w155 h45", "💾 ΑΠΟΘΗΚΕΥΣΗ")
    SaveBtn.OnEvent("Click", SaveData)
    
    InstructionsBtn := MyGui.Add("Button", "x680 y620 w155 h45", "💡 ΟΔΗΓΙΕΣ")
    InstructionsBtn.OnEvent("Click", ShowInstructions)
    
    InfoBtn := MyGui.Add("Button", "x845 y620 w120 h45", "ℹ️ INFO")
    InfoBtn.OnEvent("Click", ShowInfo)
    
    ExitBtn := MyGui.Add("Button", "x975 y620 w115 h45", "❌ ΕΞΟΔΟΣ")
    ExitBtn.OnEvent("Click", GuiClose)

    ; Ενημέρωση λιστών
    UpdateExpensesList()
    UpdateOwnersList()
    UpdateBalance()

    MyGui.Show("w1110 h705")
    StatusBar.SetText("✅ Το πρόγραμμα είναι έτοιμο προς χρήση!")
}

; ═══════════════════════════════════════════════════════════
; ΕΚΚΙΝΗΣΗ ΠΡΟΓΡΑΜΜΑΤΟΣ
; ═══════════════════════════════════════════════════════════
MAIN_PROGRAM()