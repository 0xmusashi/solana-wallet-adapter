import axios from 'axios';
import bs58 from 'bs58';
import { Transaction, SystemProgram, PublicKey } from '@solana/web3.js';
import {
    TOKEN_PROGRAM_ID,
    TokenInstruction,
    decodeTransferCheckedInstruction,
    decodeTransferInstruction,
} from '@solana/spl-token';

import { RELAYER_API } from './constants';

export const getAllowedPrograms = async (): Promise<string[]> => {
    try {
        const response = await axios.get(`${RELAYER_API}/programs`);
        return response.data.data.programs;
    } catch (error) {
        console.error('Error fetching allowed programs:', error);
        throw error;
    }
};

export const checkAllowedProgram = async (programdId: string): Promise<boolean> => {
    try {
        const response = await axios.get(`${RELAYER_API}/programs/${programdId}`);
        return response.data.data.isAllowed;
    } catch (error) {
        console.error('Error fetching allowed programs:', error);
        throw error;
    }
};

export const checkAllowedToken = async (mintToken: string): Promise<boolean> => {
    try {
        const response = await axios.get(`${RELAYER_API}/tokens/${mintToken}`);
        return response.data.data.isAllowed;
    } catch (error) {
        console.error('Error fetching allowed tokens:', error);
        throw error;
    }
};

export const relayerSignTransaction = async (encodedTx: string): Promise<Transaction> => {
    try {
        const response = await axios.post(`${RELAYER_API}/signTransaction`, {
            transaction: encodedTx,
        });
        const tx = Transaction.from(bs58.decode(response.data.data.signedTransaction));
        return tx;
    } catch (error) {
        console.error('Error fetching allowed tokens:', error);
        throw error;
    }
};

export const relayerTransferTransaction = async (encodedTx: string): Promise<Transaction> => {
    try {
        const response = await axios.post(`${RELAYER_API}/signTransaction`, {
            transaction: encodedTx,
        });
        const tx = Transaction.from(bs58.decode(response.data.data.signedTransaction));
        return tx;
    } catch (error) {
        console.error('Error fetching allowed tokens:', error);
        throw error;
    }
};

export const isSolTransfer = (transaction: Transaction): boolean => {
    if (!transaction || !transaction.instructions) {
        return false; // Invalid transaction
    }

    for (const instruction of transaction.instructions) {
        if (
            instruction.programId.equals(SystemProgram.programId) &&
            instruction.data &&
            instruction.data.length >= 8 // Basic sanity check
        ) {
            // Check if the instruction data matches the transfer instruction layout
            const instructionType = instruction.data.readUInt32LE(0); // First 4 bytes
            if (instructionType === 2) {
                // 2 is the instruction type for SystemProgram.transfer
                return true;
            }
        }
    }

    return false; // No transfer instruction found
};

export const isSPLTokenTransfer = (transaction: Transaction): boolean => {
    return transaction.instructions.some((ix) => {
        if (!ix.programId.equals(TOKEN_PROGRAM_ID)) return false;

        const decoded = decodeTransferCheckedInstruction(ix);
        return decoded?.data.instruction === TokenInstruction.TransferChecked;
    });
};
