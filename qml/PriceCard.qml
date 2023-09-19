import Blockstream.Green
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

WalletHeaderCard {
    // TODO: remove this property, only required for formatAmount which should be refactored
    required property Account account

    id: self
    contentItem: ColumnLayout {
        spacing: 10
        RowLayout {
            spacing: 10
            Image {
                opacity: 0.6
                source: 'qrc:/svg2/bolt.svg'
            }
            Label {
                font.capitalization: Font.AllUppercase
                font.family: 'SF Compact Display'
                font.pixelSize: 12
                font.weight: 400
                opacity: 0.6
                text: 'Price Feed'
            }
            HSpacer {
            }
        }
        VSpacer {
        }
        Label {
            font.capitalization: Font.AllUppercase
            font.family: 'SF Compact Display'
            font.pixelSize: 24
            font.weight: 600
            text: {
                const ticker = self.account.session.events.ticker
                const pricing = self.account.session.settings.pricing;
                const { fiat, fiat_currency } = self.context.wallet.convert({ btc: '1' })
                return fiat + ' ' + fiat_currency
            }
        }
        Label {
            font.capitalization: Font.AllUppercase
            font.family: 'SF Compact Display'
            font.pixelSize: 16
            font.weight: 400
            opacity: 0.6
            text: 'Bitcoin (BTC)' // formatFiat(card.balance)
        }
        VSpacer {
        }
    }
}