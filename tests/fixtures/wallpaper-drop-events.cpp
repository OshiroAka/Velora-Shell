// Native platform drag delivery follows Qt's qquickdroparea tests. No internal
// Drag.source or synthetic calls to the production signal handlers are used.
#include <QGuiApplication>
#include <QJsonArray>
#include <QJsonDocument>
#include <QMimeData>
#include <QQmlExpression>
#include <QQmlContext>
#include <QQuickItem>
#include <QQuickView>
#include <QUrl>
#include <qpa/qplatformdrag.h>
#include <qpa/qwindowsysteminterface.h>
#include <iostream>

int main(int argc, char **argv) {
    QGuiApplication app(argc, argv);
    QQuickView view;
    view.setSource(QUrl::fromLocalFile(QString::fromLocal8Bit(argv[1])));
    if (view.status() != QQuickView::Ready) return 1;
    auto *target = view.rootObject();
    QWindow elsewhere;
    QMimeData data;
    const QPoint position(50, 20);
    auto check = [](bool ok, const char *message) {
        if (!ok) { std::cerr << message << '\n'; std::exit(1); }
    };
    auto enter = [&](const QList<QUrl> &urls, Qt::DropActions actions = Qt::CopyAction | Qt::MoveAction) {
        data.setUrls(urls);
        return QWindowSystemInterface::handleDrag(&view, &data, position, actions, {}, {});
    };
    auto leave = [&]() {
        QWindowSystemInterface::handleDrag(&elsewhere, &data, position, Qt::CopyAction, {}, {});
        check(!target->property("containsDrag").toBool(), "Leaving/cancelling must clear wallpaper feedback");
    };
    const QUrl uri = QUrl::fromLocalFile(QString::fromLocal8Bit(argv[2]));
    const QList<QUrl> rejected = {QUrl("https://example.com/photo.jpg"), QUrl("file://remote/clip.mp4"),
        QUrl(uri.toString() + ".crdownload"), QUrl("file:///tmp/notes.txt")};
    for (const auto &url : rejected) {
        check(!enter({url}).isAccepted(), "Unsupported drag accepted");
        check(!target->property("containsDrag").toBool(), "Unsupported drag changed the weather state");
        leave();
    }
    check(!enter({uri}, Qt::MoveAction).isAccepted(), "Import must never promise to delete/move a download");
    leave();
    for (const auto &suffix : {QString(), QString(".MP4"), QString(".gif")}) {
        const QUrl url(uri.toString() + suffix);
        check(enter({url}).isAccepted(), "Local downloaded media rejected");
        check(target->property("containsDrag").toBool(), "Weather must enter the wallpaper state");
        leave();
    }
    check(enter({uri, uri, QUrl("https://example.com/no.jpg")}).isAccepted(), "Mixed drag rejected");
    const auto response = QWindowSystemInterface::handleDrop(&view, &data, position, Qt::CopyAction | Qt::MoveAction, {}, {});
    check(response.isAccepted() && response.acceptedAction() == Qt::CopyAction, "Drop must report a copy");
    check(target->property("dropCount").toInt() == 1, "Drop dispatched more than once");
    QQmlExpression received(qmlContext(target), target, "JSON.stringify(received)");
    const auto serialized = received.evaluate().toString();
    const auto urls = QJsonDocument::fromJson(serialized.toUtf8()).array();
    check(urls.size() == 1 && QUrl(urls.first().toString()) == uri, "Drop must preserve the local URL and filter duplicates/web links");
    check(!target->property("containsDrag").toBool(), "Drop must clear wallpaper feedback");
    target->setEnabled(false);
    check(!enter({uri}).isAccepted(), "Editing the bar must disable the drop target");
    check(target->property("dropCount").toInt() == 1, "Disabled target dispatched an import");
    std::cout << "WALLPAPER_DROP_EVENTS_OK\n";
}
