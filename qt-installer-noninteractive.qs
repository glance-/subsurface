// http://stackoverflow.com/a/34032216/78204

function Controller() {
    installer.autoRejectMessageBoxes();
    installer.setMessageBoxAutomaticAnswer("OverwriteTargetDirectory", QMessageBox.Yes);
    installer.installationFinished.connect(function() {
        gui.clickButton(buttons.NextButton);
    })
}

Controller.prototype.WelcomePageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.CredentialsPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.IntroductionPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.TargetDirectoryPageCallback = function()
{
    gui.currentPageWidget().TargetDirectoryLineEdit.setText(installer.value("HomeDir") + "/Qt");
    //gui.currentPageWidget().TargetDirectoryLineEdit.setText("/scratch/Qt");
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.ComponentSelectionPageCallback = function() {
    var widget = gui.currentPageWidget();

    widget.selectAll();

//    widget.deselectAll();
//    widget.selectComponent("qt.57.android_armv7");

//    widget.selectComponent("qt.57.qtquickcontrols");
//    widget.selectComponent("qt.57.qtquickcontrols.android_armv7");

//    widget.deselectComponent("qt.tools.qtcreator");
//    widget.deselectComponent("qt.57.qt3d");
//    widget.deselectComponent("qt.57.qtcanvas3d");
//    widget.deselectComponent("qt.57.qtlocation");
//    widget.deselectComponent("qt.57.qtquick1");
//    widget.deselectComponent("qt.57.qtscript");
//    widget.deselectComponent("qt.57.qtwebengine");
//    widget.deselectComponent("qt.extras");
//    widget.deselectComponent("qt.tools.doc");
//    widget.deselectComponent("qt.tools.examples");
//    widget.deselectComponent("qt.57.examples");
//    widget.deselectComponent("qt.57.doc");

    gui.clickButton(buttons.NextButton);
}

Controller.prototype.LicenseAgreementPageCallback = function() {
    gui.currentPageWidget().AcceptLicenseRadioButton.setChecked(true);
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.StartMenuDirectoryPageCallback = function() {
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.ReadyForInstallationPageCallback = function()
{
    gui.clickButton(buttons.NextButton);
}

Controller.prototype.FinishedPageCallback = function() {
var checkBoxForm = gui.currentPageWidget().LaunchQtCreatorCheckBoxForm
if (checkBoxForm && checkBoxForm.launchQtCreatorCheckBox) {
    checkBoxForm.launchQtCreatorCheckBox.checked = false;
}
    gui.clickButton(buttons.FinishButton);
}
