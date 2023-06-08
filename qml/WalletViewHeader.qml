import Blockstream.Green.Core
import Blockstream.Green
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Shapes
import QtQml
import Qt5Compat.GraphicalEffects

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

MainPageHeader {
    required property Context context
    required property Wallet wallet
    required property Account currentAccount
    readonly property bool archived: self.currentAccount ? self.currentAccount.hidden : false
    required property real accountListWidth
    property Item toolbarItem: toolbar
    id: self

    topPadding: 0
    leftPadding: 0
    rightPadding: 0

    component HPane: GPane {
        padding: 4
        Layout.fillWidth: true
        leftPadding: constants.p3
        rightPadding: constants.p3
        background: null
    }

    component TMenuSeparator: Rectangle {
        Layout.fillWidth: true
        Layout.minimumHeight: 1
        Layout.maximumHeight: 1
        color: 'white'
        opacity: 0.05
    }

    component TMenuItem: AbstractButton {
        id: self

        readonly property var details: {
            const re = /^([^\(\)]+)(?: \((\d+)\))?$/
            const [_, text, count] = re.exec(self.text)
            return { text, count: Number(count ?? '0') }
        }

        Layout.fillWidth: true
        leftPadding: 24
        rightPadding: 24
        topPadding: 8
        bottomPadding: 8

        background: Rectangle {
            color: 'white'
            opacity: 0.05
            visible: self.enabled && self.hovered
        }

        contentItem: RowLayout {
            spacing: 12
            Image {
                Layout.preferredHeight: 24
                Layout.preferredWidth: 24
                fillMode: Image.PreserveAspectFit
                source: self.icon.source
                opacity: self.enabled ? 1 : 0.25
            }
            Label {
                Layout.fillWidth: true
                text: self.details?.text ?? ''
                font.pixelSize: 14
                font.weight: 400
            }
            Label {
                background: Rectangle {
                    color: 'black'
                    radius: height / 2
                    opacity: 0.25
                }
                text: self.details.count
                visible: self.details.count > 0
                topPadding: 4
                bottomPadding: 4
                leftPadding: 12
                rightPadding: 12
                font.pixelSize: 12
                font.weight: 400
                font.bold: true
            }
        }
    }

    component WalletMenu: Popup {
        id: menu
        padding: 0
        background: Item {
            DropShadow {
                opacity: 0.5
                verticalOffset: 8
                radius: 32
                samples: 16
                source: r
                anchors.fill: r
            }
            Rectangle {
                rotation: 45
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.top
                anchors.verticalCenterOffset: 2
                color: '#343842'
                width: 7
                height: 7
            }
            Rectangle {
                id: r
                color: '#222226'
                border.color: '#343842'
                border.width: 0.5
                radius: 10
                anchors.fill: parent
            }
            Rectangle {
                rotation: 45
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.top
                anchors.verticalCenterOffset: 2
                color: '#222226'
                width: 5.5
                height: 5.5
            }
        }

        contentItem: ColumnLayout {
            id: content_item
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle {
                    width: content_item.width
                    height: content_item.height
                    radius: 9
                }
            }

            spacing: 0
            TMenuItem {
                enabled: name_field_loader.active
                text: qsTrId('id_rename')
                icon.source: 'qrc:/svg/wallet-rename.svg'
                onClicked: {
                    menu.close()
                    name_field_loader.item.forceActiveFocus()
                }
            }
            TMenuSeparator {
            }
            TMenuItem {
                text: qsTrId('id_settings')
                icon.source: 'qrc:/svg/wallet-settings.svg'
                enabled: {
                    if (self.context.watchonly) return false
                    // TODO
                    if (self.wallet.network.electrum) return true
                    return !!self.context.settings.pricing
                }
                onClicked: {
                    menu.close()
                    navigation.set({ settings: true })
                }
            }
            TMenuSeparator {
            }
            TMenuItem {
                text: qsTrId('id_add_new_account')
                icon.source: 'qrc:/svg/new.svg'
                enabled: !self.context.watchonly
                onClicked: {
                    menu.close()
                    openCreateDialog()
                }
            }
            TMenuSeparator {
            }
            TMenuItem {
                text: qsTrId('id_view_archived_accounts_d').arg(archive_list_model.count)
                icon.source: 'qrc:/svg/archived.svg'
                enabled: archive_list_model.count > 0 && !(navigation.param.archive ?? false)
                onClicked: {
                    menu.close()
                    navigation.set({ archive: true })
                }
            }
            TMenuSeparator {
            }
            TMenuItem {
                text: qsTrId('id_logout')
                icon.source: 'qrc:/svg/logout.svg'
                enabled: !!self.context
                onClicked: {
                    menu.close()
                    self.wallet.disconnect()
                }
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: 0
        AlertView {
            id: alert_view
            alert: overview_alert
        }
        HPane {
//            leftPadding: constants.p3 - 8
            contentItem: RowLayout {
                spacing: 0
                Control {
                    Layout.maximumWidth: self.width / 3
                    padding: 2
                    leftPadding: 0
                    background: null
                    contentItem: RowLayout {
                        spacing: 8
                        Label {
                            verticalAlignment: Qt.AlignVCenter
                            text: 'Overview'
                            font.pixelSize: 18
                            font.styleName: 'Medium'
                        }
                        Label {
                            verticalAlignment: Qt.AlignVCenter
                            leftPadding: 8
                            text: '/'
                            opacity: 0.5
                            font.pixelSize: 18
                            font.styleName: 'Medium'
                        }
                        Loader {
                            id: name_field_loader
                            active: wallet.persisted
                            visible: active
                            Layout.fillWidth: true
                            sourceComponent: EditableLabel {
                                id: editable_label
                                leftPadding: 8
                                rightPadding: 8
                                font.pixelSize: 18
                                font.styleName: 'Medium'
                                text: wallet.name
                                onAccepted: () => {
                                    if (wallet.rename(editable_label.text, false)) {
                                        Analytics.recordEvent('wallet_rename')
                                    }
                                    tool_button.forceActiveFocus()
                                }
                                onEdited: (text, activeFocus) => {
                                    if (wallet.rename(text, activeFocus)) {
                                        Analytics.recordEvent('wallet_rename')
                                    }
                                }
                            }
                        }
                        Loader {
                            Layout.minimumHeight: 42
                            active: !wallet.persisted
                            visible: active
                            sourceComponent: Label {
                                verticalAlignment: Qt.AlignVCenter
                                text: wallet.name
                                font.pixelSize: 18
                                font.styleName: 'Medium'
                            }
                        }
                    }
                }
                Image {
                    visible: false
                    fillMode: Image.PreserveAspectFit
                    sourceSize.height: 16
                    sourceSize.width: 16
                    source: 'qrc:/svg/right.svg'
                    Layout.alignment: Qt.AlignVCenter
                }
                ToolButton {
                    id: tool_button
                    icon.source: 'qrc:/svg/3-h-dots.svg'
                    onClicked: if (!wallet_menu.visible) wallet_menu.open()
                    WalletMenu {
                        id: wallet_menu
                        x: (tool_button.width - wallet_menu.width) / 2
                        y: tool_button.height
                    }
                }
                HSpacer {
                }
                RowLayout {
                    Layout.fillWidth: false
                    spacing: constants.s1
                    ToolButton {
                        visible: (wallet.context.events.twofactor_reset?.is_active ?? false) || !fiatRateAvailable
                        icon.source: 'qrc:/svg/notifications_2.svg'
                        icon.color: 'transparent'
                        icon.width: 16
                        icon.height: 16
                        onClicked: notifications_drawer.open()
                    }
                    ToolButton {
                        visible: false
                        icon.source: 'qrc:/svg/refresh.svg'
                        flat: true
                        action: self.refreshAction
                        ToolTip.text: qsTrId('id_refresh')
                        ToolTip.delay: 300
                        ToolTip.visible: hovered
                    }
                    ToolButton {
                        visible: false
                        icon.source: 'qrc:/svg/logout.svg'
                        flat: true
//                        action: self.disconnectAction
                        ToolTip.text: qsTrId('id_logout')
                        ToolTip.delay: 300
                        ToolTip.visible: hovered
                    }
                    ToolButton {
                        visible: false
                        flat: true
//                        action: self.settingsAction
                        ToolTip.text: qsTrId('id_settings')
                        ToolTip.delay: Qt.styleHints.mousePressAndHoldInterval
                        ToolTip.visible: hovered
                    }
                }
            }
        }
        HPane {
            visible: false
            contentItem: RowLayout {
                spacing: 8
                TotalBalanceCard {
                    context: self.context
                }
                HSpacer {
                }
            }
        }
        HPane {
            contentItem: RowLayout {
                id: toolbar
                Layout.fillWidth: true
                Layout.fillHeight: false
                spacing: 24
                Label {
                    Layout.minimumWidth: self.accountListWidth
                    text: qsTrId('id_accounts')
                    font.pixelSize: 16
                    font.bold: true
                }
                RowLayout {
                    Layout.fillWidth: false
                    spacing: 24
                    TabButton2 {
                        view: 'overview'
                        enabled: self.currentAccount?.network.liquid ?? false
                    }
                    TabButton2 {
                        view: 'assets'
                        enabled: self.currentAccount?.network.liquid ?? false
                    }
                    TabButton2 {
                        view: 'transactions'
                    }
                    TabButton2 {
                        view: 'addresses'
                    }
                    TabButton2 {
                        view: 'coins'
                    }
                }
                HSpacer {
                }
            }
        }
    }

    component TabButton2: Button {
        id: tab_button
        required property string view
        padding: 0
        verticalPadding: 0
        topPadding: 4
        bottomPadding: 4
        leftPadding: 0
        rightPadding: 0
        background: null
        checked: navigation.param.view === tab_button.view
        visible: enabled
        action: Action {
            text: qsTrId('id_' + tab_button.view)
            shortcut: {
                let j = -1
                for (let i = 0; i < parent.children.length; i++) {
                    const item = parent.children[i]
                    if (!item.visible) continue
                    j ++
                    if (item === tab_button) return 'Ctrl+' + (j + 1)
                }
                return null
            }
            onTriggered: navigation.set({ view: tab_button.view })
        }
        contentItem: Label {
            text: tab_button.text
            opacity: tab_button.checked ? 1 : 0.5
            font.pixelSize: 16
            font.bold: true
            horizontalAlignment: Label.AlignHCenter
        }
    }

    property Action refreshAction: Action {
        // TODO reload from be done from a controller, not from wallet or context
        enabled: false
    }

    component TotalBalanceCard: GPane {
        required property Context context
        readonly property var balance: {
            let r = 0
            for (let i = 0; i < self.context?.accounts.length; i++) {
                const account = self.context.accounts[i]
                r += account.balance
            }
            return r
        }

        Layout.minimumHeight: 64
        Layout.minimumWidth: 250
        id: self
        padding: 8
        background: Rectangle {
            radius: 4
            opacity: 0.1
//            border.width: 0.5
//            border.color: Qt.alpha(constants.c500, 1)
            color: 'black' //Qt.alpha(constants.c500, 0.25)
        }
        contentItem: ColumnLayout {
            SectionLabel {
                text: qsTrId('id_total_balance')
            }
            VSpacer {
            }
            Label {
                text: formatFiat(self.balance)
                font.pixelSize: 12
                font.weight: 400
            }
            Label {
                text: formatAmount(self.balance)
                font.pixelSize: 16
                font.weight: 600
            }
        }
    }

}
