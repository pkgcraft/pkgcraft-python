import logging

from . cimport pkgcraft_c as C

logging.basicConfig()
logger = logging.getLogger('pkgcraft')


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


def _pkgcraft_log_test(str message not None, int level):
    """Inject log messages into pkgcraft to replay for test purposes."""
    cdef C.PkgcraftLog log
    log_bytes = message.encode()
    log.message = log_bytes

    # convert from python logging levels to pkgcraft ones
    level = level // 10
    if level == C.LOG_LEVEL_ERROR:
        log.level = C.LOG_LEVEL_ERROR
    elif level == C.LOG_LEVEL_WARN:
        log.level = C.LOG_LEVEL_WARN
    elif level == C.LOG_LEVEL_INFO:
        log.level = C.LOG_LEVEL_INFO
    else:
        log.level = C.LOG_LEVEL_DEBUG

    C.pkgcraft_log_test(&log)


# progagate pkgcraft log messages to python on module import
C.pkgcraft_logging_enable(pkgcraft_logger)
