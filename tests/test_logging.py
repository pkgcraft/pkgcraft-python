import logging

from pkgcraft.logging import _pkgcraft_log_test, logger


def test_logging(caplog):
    for level in (logging.ERROR, logging.WARNING, logging.INFO, logging.DEBUG):
        # verify the expected log level and message are returned
        logger.setLevel(level)
        name = logging.getLevelName(level)
        _pkgcraft_log_test(name, level)
        assert caplog.record_tuples == [("pkgcraft", level, name)]
        caplog.clear()

        # filter all log levels
        logger.setLevel(100)
        _pkgcraft_log_test(name, level)
        assert not caplog.record_tuples
        caplog.clear()
