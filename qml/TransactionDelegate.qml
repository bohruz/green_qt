import Blockstream.Green
import Blockstream.Green.Core
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

import "analytics.js" as AnalyticsJS
import "util.js" as UtilJS

ItemDelegate {
    signal transactionClicked(Transaction transaction)
    required property Transaction transaction
    required property Account account
    required property Context context

    property var tx: transaction.data
    property int confirmations: transactionConfirmations(transaction)
    readonly property var spv: {
        const liquid = transaction.account.network.liquid
        const unconfirmed = (liquid && confirmations < 2) || (!liquid && confirmations < 6)
        if (unconfirmed) return null
        switch (transaction.spv) {
        case Transaction.Disabled:
        case Transaction.Unconfirmed:
        case Transaction.Verified:
            return null
        case Transaction.NotVerified:
            return { icon: 'qrc:/svg/tx-spv-not-verified.svg', text: qsTrId('id_invalid_merkle_proof') }
        case Transaction.NotLongest:
            return { icon: 'qrc:/svg/tx-spv-not-longest.svg', text: qsTrId('id_not_on_longest_chain') }
        case Transaction.InProgress:
            return { icon: 'qrc:/svg/tx-spv-in-progress.svg', text: qsTrId('id_verifying_transactions') }
        }
    }

    onClicked: self.transactionClicked(transaction)

    id: self
    focusPolicy: Qt.ClickFocus
    leftPadding: 20
    rightPadding: 20
    topPadding: 20
    bottomPadding: 20
    background: Item {
        Rectangle {
            anchors.fill: parent
            visible: self.hovered
            color: '#00B45A'
            opacity: 0.08
        }
        Rectangle {
            color: '#1F222A'
            width: parent.width
            height: 1
            y: parent.height - 1
        }
    }
    spacing: 0

    function txType(tx) {
        if (transaction.type === Transaction.Incoming) {
            if (tx.outputs.length > 0) {
                for (const o of tx.outputs) {
                    if (o.is_relevant) {
                        return qsTrId('id_received')
                    }
                }
            } else {
                return qsTrId('id_received')
            }
        }
        if (transaction.type === Transaction.Outgoing) {
            return qsTrId('id_sent')
        }
        if (transaction.type === Transaction.Redeposit) {
            return qsTrId('id_redeposited')
        }
        if (transaction.type === Transaction.Mixed) {
            return qsTrId('id_swap')
        }
        return JSON.stringify(tx, null, '\t')
    }
    Action {
        id: copy_unblinding_data_action
        text: qsTrId('id_copy_unblinding_data')
        onTriggered: copyUnblindingData(tool_button, tx)
    }
    contentItem: RowLayout {
        spacing: 20
        Image {
            Layout.alignment: Qt.AlignCenter
            source: `qrc:/svg2/tx-${transaction.data.type}.svg`
        }
        ColumnLayout {
            Layout.fillWidth: false
            Layout.fillHeight: false
            Layout.alignment: Qt.AlignCenter
            spacing: 1
            Label {
                color: '#FFF'
                font.pixelSize: 14
                font.weight: 600
                text: txType(tx)
            }
            Label {
                color: '#929292'
                text: UtilJS.formatTransactionTimestamp(tx)
                font.pixelSize: 12
                font.weight: 400
                font.capitalization: Font.AllUppercase
                opacity: 0.6
            }
        }
        Label {
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: 0
            Layout.fillWidth: true
            color: '#929292'
            font.pixelSize: 12
            font.weight: 400
            text: {
                const lines = transaction.memo.trim().split('\n')
                return lines[0] + (lines.length > 1 ? '...' : '')
            }
            wrapMode: Label.Wrap
        }
        TransactionStatusBadge {
            transaction: self.transaction
            confirmations: self.confirmations
            visible: confirmations < (transaction.account.network.liquid ? 1 : 6)
        }
        Loader {
            active: spv
            visible: active
            sourceComponent: Image {
                smooth: true
                mipmap: true
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignHCenter
                source: spv.icon
                sourceSize.height: 24
            }
        }
        ColumnLayout {
            Layout.fillWidth: false
            spacing: 1
            Repeater {
                model: {
                    const assets = []
                    if (self.account.network.liquid) {
                        for (const [id, satoshi] of Object.entries(transaction.data.satoshi)) {
                            if (self.account.network.policyAsset === id) continue
                            const asset = AssetManager.assetWithId(self.account.context.deployment, id)
                            assets.push({ asset, satoshi: String(satoshi) })
                        }
                    }
                    return assets
                }
                delegate: Label {
                    Convert {
                        id: convert
                        account: self.account
                        asset: modelData.asset
                        input: ({ satoshi: modelData.satoshi })
                    }
                    Layout.alignment: Qt.AlignRight
                    color: transaction.data.type === 'incoming' ? '#00B670' : '#FFF'
                    font.pixelSize: 14
                    font.weight: 600
                    text: convert.output.label
                }
            }
            Convert {
                id: convert
                account: self.account
                input: {
                    const network = transaction.account.network
                    const satoshi = transaction.data.satoshi
                    return { satoshi: String(satoshi[network.policyAsset] ?? 0) }
                }
                unit: self.account.session.unit
            }
            Label {
                Layout.alignment: Qt.AlignRight
                color: transaction.data.type === 'incoming' ? '#00B670' : '#FFF'
                font.pixelSize: 14
                font.weight: 600
                text: convert.output.label
                visible: Number(convert.result.satoshi ?? '0') !== 0
            }
            Label {
                Layout.alignment: Qt.AlignRight
                color: '#929292'
                font.pixelSize: 12
                font.weight: 400
                text: convert.fiat.label
                visible: Number(convert.result.satoshi ?? '0') !== 0
            }
        }
        Item {
            Layout.minimumWidth: 32
            visible: self.account.network.liquid && assets_repeater.count === 0
        }
        Repeater {
            id: assets_repeater
            model: {
                const assets = []
                if (self.account.network.liquid) {
                    for (const [id, satoshi] of Object.entries(transaction.data.satoshi)) {
                        if (self.account.network.policyAsset === id) continue
                        const asset = AssetManager.assetWithId(self.account.context.deployment, id)
                        if (asset && asset.icon) assets.push(asset)
                    }
                }
                return assets
            }
            delegate: AssetIcon {
                asset: modelData
            }
        }

    }
}
