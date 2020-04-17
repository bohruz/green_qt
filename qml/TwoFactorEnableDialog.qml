import Blockstream.Green 0.1
import QtQuick 2.13
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ControllerDialog {
    property string method

    id: controller_dialog
    title: qsTr('id_set_up_twofactor_authentication')
    modal: true
    doneText: qsTr('id_enabled')

    controller: TwoFactorController {
        method: controller_dialog.method
    }

    initialItem: method === 'gauth' ? gauth_component : generic_component

    Component {
        id: generic_component
        ColumnLayout {
            property list<Action> actions: [
                Action {
                    text: qsTrId('id_next')
                    enabled: data_field.text !== ''
                    onTriggered: controller.enable(data_field.text)
                }
            ]
            Image {
                source: `svg/2fa_${method}.svg`
                sourceSize.width: 64
                sourceSize.height: 64
                opacity: matching ? 1 : 0
                Behavior on opacity { OpacityAnimator { } }
                Layout.alignment: Qt.AlignHCenter
            }
            Label {
                id: description_text
                text: description
                wrapMode: Text.WordWrap
                Layout.alignment: Qt.AlignHCenter
            }
            TextField {
                id: data_field
                placeholderText: placeholder
                selectByMouse: true
                Layout.fillWidth: true
                Layout.minimumWidth: 300
                Layout.alignment: Qt.AlignHCenter
            }
        }

    }

    Component {
        id: gauth_component
        ColumnLayout {
            property list<Action> actions: [
                Action {
                    text: qsTr('id_next')
                    onTriggered: controller.enable(wallet.config[method].data)
                }
            ]
            RowLayout {
                Image {
                    source: `svg/2fa_${method}.svg`
                    sourceSize.width: 32
                    sourceSize.height: 32
                }
                Label {
                    Layout.fillWidth: true
                    text: qsTr('id_scan_the_qr_code_in_google')
                    wrapMode: Text.WordWrap
                }
            }
            QRCode {
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: wallet.config[method].data
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: wallet.config[method].data.split('=')[1]
                color: 'green'
            }
            Item {
                Layout.fillHeight: true
                Layout.fillWidth: true
            }
        }
    }
}
