import logging

from pkgcraft.logging import _pkgcraft_log_test, logger


def test_logging(caplog):
    for level in (logging.ERROR, logging.WARNING, logging.INFO, logging.DEBUG):
        # verify the expected log level and message are returned
        logger.setLevel(level)
        name = logging.getLevelName(level)
        _pkgcraft_log_test(name, level)
        assert caplog.record_tuples == [("pkgcraft", level, name)], f"failed log level: {name}"
        caplog.clear()

        # filter log level
        logger.setLevel(level + 10)
        _pkgcraft_log_test(name, level)
        assert not caplog.record_tuples
        caplog.clear()
