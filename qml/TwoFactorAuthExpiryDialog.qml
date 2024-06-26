import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ControllerDialog {
    required property Session session

    id: self

    title: qsTrId('id_twofactor_authentication_expiry')
//    doneText: qsTrId('id_twofactor_authentication_expiry')

    controller: Controller {
        id: controller
        context: self.context
    }

    component Option: DescriptiveRadioButton {
        required property int index
        readonly property int value: self.session.network.data.csv_buckets[index]
        Layout.maximumWidth: 500
        checked: self.session.settings.csvtime === value
        enabled: true
        ButtonGroup.group: type_button_group
        Layout.fillWidth: true
    }

    ColumnLayout {
        spacing: constants.s1
        ButtonGroup {
            id: type_button_group
            exclusive: true
        }
        Option {
            index: 0
            text: qsTrId('id_6_months_25920_blocks')
            description: qsTrId('id_optimal_if_you_spend_coins')
        }
        Option {
            index: 1
            text: qsTrId('id_12_months_51840_blocks')
            description: qsTrId('id_wallet_coins_will_require')
        }
        Option {
            index: 2
            text: qsTrId('id_15_months_65535_blocks')
            description: qsTrId('id_optimal_if_you_rarely_spend')
        }
        RowLayout {
            HSpacer {
            }
            GButton {
                large: true
                text: qsTrId('id_next')
                highlighted: true
                enabled: type_button_group.checkedButton && type_button_group.checkedButton.value !== self.session.settings.csvtime
                onClicked: {
                    controller.setCsvTime(type_button_group.checkedButton.value)
//                    dialog.doneText = qsTrId('id_twofactor_authentication_expiry') + " : " + type_button_group.checkedButton.text
                }
            }
        }
    }
}
