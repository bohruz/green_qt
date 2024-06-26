#include "application.h"
#include "walletmanager.h"

#include <QFileOpenEvent>
#include <QWindow>

Application::Application(int& argc, char** argv)
    : QApplication(argc, argv)
{
}

void Application::raise()
{
    for (QWindow* window : allWindows()) {
        // windows: does not allow a window to be brought to front while the user has focus on another window
        // instead, Windows flashes the taskbar button of the window to notify the user

        // mac: if the primary window is minimized, it is restored. It is background, it is brough to foreground
        if (window->visibility() == QWindow::Hidden || window->visibility() == QWindow::Minimized) {
            window->setVisibility(QWindow::AutomaticVisibility);
        }
        window->requestActivate();
        window->raise();
    }
}

bool Application::event(QEvent* event)
{
    if (event->type() == QEvent::FileOpen) {
        auto open_event = static_cast<QFileOpenEvent*>(event);
        WalletManager::instance()->setOpenUrl(open_event->url().toString());
        raise();
    }
    return QApplication::event(event);
}
