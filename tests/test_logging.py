import logging

from pkgcraft.logging import _pkgcraft_log_test, logger


def test_logging(caplog):
    for level in (logging.ERROR, logging.WARNING, logging.INFO, logging.DEBUG):
        # verify the expected level and message are returned
        logger.setLevel(level)
        name = logging.getLevelName(level)
        _pkgcraft_log_test(name, level)
        assert caplog.record_tuples == [("pkgcraft", level, name)], f"failed level: {name}"
        caplog.clear()

        # setting a higher level filters the message
        logger.setLevel(level + 10)
        _pkgcraft_log_test(name, level)
        assert not caplog.record_tuples
        caplog.clear()

        # setting a lower level passes the message, except when 0 since root
        # loggers default to WARNING level when passed 0
        if newLevel := level - 10:
            logger.setLevel(newLevel)
            _pkgcraft_log_test(name, level)
            assert caplog.record_tuples == [("pkgcraft", level, name)], f"failed level: {name}"
            caplog.clear()
