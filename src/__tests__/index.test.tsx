import { isUAEPassError, UAEPassErrorCode } from '../index';

describe('isUAEPassError', () => {
  it('accepts a rejection carrying a UAE PASS error code', () => {
    const error = Object.assign(new Error('User cancelled'), {
      code: UAEPassErrorCode.CANCELLED,
      userInfo: { error: 'cancelledOnApp' },
    });
    expect(isUAEPassError(error)).toBe(true);
    if (isUAEPassError(error)) {
      expect(error.userInfo?.error).toBe('cancelledOnApp');
    }
  });

  it('rejects other errors and non-errors', () => {
    expect(isUAEPassError(new Error('boom'))).toBe(false);
    expect(isUAEPassError({ code: 'E_SOMETHING_ELSE' })).toBe(false);
    expect(isUAEPassError(null)).toBe(false);
    expect(isUAEPassError('CANCELLED')).toBe(false);
  });
});
