import { WalletError } from 'sol-wallet-adapter-base';

export class WalletNotSelectedError extends WalletError {
    name = 'WalletNotSelectedError';
}
