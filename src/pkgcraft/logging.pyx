import logging

from . cimport pkgcraft_c as C

logging.basicConfig()
logger = logging.getLogger('pkgcraft')


cdef void pkgcraft_logger(C.PkgcraftLog *log):
    msg = log.message.decode()

    if log.level in (C.LogLevel.LOG_LEVEL_DEBUG, C.LogLevel.LOG_LEVEL_TRACE):
        logger.debug(msg)
    elif log.level == C.LogLevel.LOG_LEVEL_INFO:
        logger.info(msg)
    elif log.level == C.LogLevel.LOG_LEVEL_WARN:
        logger.warning(msg)
    elif log.level == C.LogLevel.LOG_LEVEL_ERROR:
        logger.error(msg)

    C.pkgcraft_log_free(log)


# progagate pkgcraft log messages to python on module import
C.pkgcraft_logging_enable(pkgcraft_logger)
