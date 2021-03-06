package org.libtorrent4j.alerts;

import org.libtorrent4j.swig.socks5_alert;

/**
 * This alert is posted with SOCKS5 related errors, when a SOCKS5 proxy is
 * configured. It's enabled with the error_notification alert category.
 *
 * @author aldenml
 */
public final class Socks5Alert extends AbstractAlert<socks5_alert> {

    Socks5Alert(socks5_alert alert) {
        super(alert);
    }
}
