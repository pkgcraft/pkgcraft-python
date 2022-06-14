import pickle

import pytest

from pkgcraft import PkgcraftError


class TestPkgcraftError:

    def test_new(self):
        with pytest.raises(PkgcraftError, match=f'error message'):
            raise PkgcraftError('error message')

    def test_pickle(self):
        e1 = PkgcraftError('error message')
        e2 = pickle.loads(pickle.dumps(e1))
        with pytest.raises(PkgcraftError, match=f'error message'):
            raise e2
