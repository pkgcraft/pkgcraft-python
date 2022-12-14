import logging

from . cimport pkgcraft_c as C

logging.basicConfig()
logger = logging.getLogger('pkgcraft')


cdef void pkgcraft_logger(int level, char *msg_p):
    msg = msg_p.decode()
    C.pkgcraft_str_free(msg_p)

    if level <= 1:
        logger.debug(msg)
    elif level == 2:
        logger.info(msg)
    elif level == 3:
        logger.warning(msg)
    elif level >= 4:
        logger.error(msg)


# progagate pkgcraft log messages to python on module import
C.pkgcraft_logging_enable(pkgcraft_logger)
