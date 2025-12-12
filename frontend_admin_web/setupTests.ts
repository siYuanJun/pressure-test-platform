// setupTests.ts
import '@testing-library/jest-dom';

// Mock umi-request
jest.mock('umi-request', () => {
  const mockRequest = {
    get: jest.fn(),
    post: jest.fn(),
    put: jest.fn(),
    delete: jest.fn(),
    interceptors: {
      request: {
        use: jest.fn(),
      },
      response: {
        use: jest.fn(),
      },
    },
  };
  return {
    extend: jest.fn(() => mockRequest),
    ...mockRequest,
  };
});

// Mock Umi hooks
jest.mock('umi', () => ({
  ...jest.requireActual('umi'),
  useLocation: jest.fn(() => ({ pathname: '/', search: '', hash: '' })),
  useParams: jest.fn(() => ({})),
  useNavigate: jest.fn(() => jest.fn()),
  useHistory: jest.fn(() => ({ push: jest.fn(), replace: jest.fn() })),
}));

// Mock react-router-dom hooks if used
jest.mock('react-router-dom', () => ({
  ...jest.requireActual('react-router-dom'),
  useNavigate: jest.fn(() => jest.fn()),
  useLocation: jest.fn(() => ({ pathname: '/', search: '', hash: '' })),
  useParams: jest.fn(() => ({})),
}));

// Mock @umijs/max hooks
jest.mock('@umijs/max', () => ({
  ...jest.requireActual('@umijs/max'),
  useNavigate: jest.fn(() => jest.fn()),
  useLocation: jest.fn(() => ({ pathname: '/', search: '', hash: '' })),
  useParams: jest.fn(() => ({})),
}));
