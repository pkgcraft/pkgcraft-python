import logging

from . cimport C


cdef void pkgcraft_logger(C.PkgcraftLog *log):
    """Callback used to inject pkgcraft log messages into python."""
    msg = log.message.decode()

    if log.level in (C.LOG_LEVEL_DEBUG, C.LOG_LEVEL_TRACE):
        logger.debug(msg)
    elif log.level == C.LOG_LEVEL_INFO:
        logger.info(msg)
    elif log.level == C.LOG_LEVEL_WARN:
        logger.warning(msg)
    elif log.level == C.LOG_LEVEL_ERROR:
        logger.error(msg)

    C.pkgcraft_log_free(log)


cdef C.LogLevel convert_level(int level):
    """Convert from python logging levels to pkgcraft ones."""
    if level < logging.DEBUG:
        return C.LOG_LEVEL_TRACE
    elif level <= logging.DEBUG:
        return C.LOG_LEVEL_DEBUG
    elif level <= logging.INFO:
        return C.LOG_LEVEL_INFO
    elif level <= logging.WARNING:
        return C.LOG_LEVEL_WARN
    elif level <= logging.ERROR:
        return C.LOG_LEVEL_ERROR
    return C.LOG_LEVEL_OFF


def _pkgcraft_log_test(str message not None, int level):
    """Inject log messages into pkgcraft to replay for test purposes."""
    C.pkgcraft_log_test(message.encode(), convert_level(level))


class PkgcraftLogger(logging.Logger):
    """Custom logger that supports switching pkgcraft log levels."""

    def setLevel(self, level):
        C.pkgcraft_logging_enable(<C.LogCallback>pkgcraft_logger, convert_level(level))
        super().setLevel(level)


logging.basicConfig()
logging.setLoggerClass(PkgcraftLogger)
logger = logging.getLogger("pkgcraft")
