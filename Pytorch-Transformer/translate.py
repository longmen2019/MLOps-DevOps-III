# Import Path for handling filesystem paths in a platform-independent way
from pathlib import Path

# Import configuration utilities: get_config loads settings, latest_weights_file_path finds model weights
from config import get_config, latest_weights_file_path 

# Import function to build the Transformer model architecture
from model import build_transformer

# Import HuggingFace Tokenizer for encoding and decoding text
from tokenizers import Tokenizer

# Import HuggingFace dataset loader
from datasets import load_dataset

# Import custom dataset wrapper for bilingual translation tasks
from dataset import BilingualDataset

# Import PyTorch for tensor operations and model handling
import torch

# Import sys to read command-line arguments
import sys

# Define the translation function that takes a sentence or index as input
def translate(sentence: str):
    # Select GPU if available, otherwise fallback to CPU
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print("Using device:", device)

    # Load configuration dictionary containing model and tokenizer settings
    config = get_config()

    # Load source language tokenizer using configured file path
    tokenizer_src = Tokenizer.from_file(str(Path(config['tokenizer_file'].format(config['lang_src']))))

    # Load target language tokenizer using configured file path
    tokenizer_tgt = Tokenizer.from_file(str(Path(config['tokenizer_file'].format(config['lang_tgt']))))

    # Build Transformer model with vocab sizes and sequence length from config, then move to device
    model = build_transformer(
        tokenizer_src.get_vocab_size(),
        tokenizer_tgt.get_vocab_size(),
        config["seq_len"],
        config['seq_len'],
        d_model=config['d_model']
    ).to(device)

    # Load the latest pretrained model weights from file
    model_filename = latest_weights_file_path(config)
    state = torch.load(model_filename)

    # Load model parameters into the Transformer
    model.load_state_dict(state['model_state_dict'])

    # Initialize label (ground truth translation) as empty string
    label = ""

    # If input is an integer or numeric string, treat it as an index into the dataset
    if type(sentence) == int or sentence.isdigit():
        id = int(sentence)

        # Load the full bilingual dataset split
        ds = load_dataset(f"{config['datasource']}", f"{config['lang_src']}-{config['lang_tgt']}", split='all')

        # Wrap dataset with tokenization and formatting logic
        ds = BilingualDataset(ds, tokenizer_src, tokenizer_tgt, config['lang_src'], config['lang_tgt'], config['seq_len'])

        # Extract source and target sentence from dataset at given index
        sentence = ds[id]['src_text']
        label = ds[id]["tgt_text"]

    # Extract sequence length from config
    seq_len = config['seq_len']

    # Set model to evaluation mode and disable gradient computation
    model.eval()
    with torch.no_grad():
        # Encode source sentence into token IDs
        source = tokenizer_src.encode(sentence)

        # Add special tokens [SOS], [EOS], and pad to fixed sequence length
        source = torch.cat([
            torch.tensor([tokenizer_src.token_to_id('[SOS]')], dtype=torch.int64), 
            torch.tensor(source.ids, dtype=torch.int64),
            torch.tensor([tokenizer_src.token_to_id('[EOS]')], dtype=torch.int64),
            torch.tensor([tokenizer_src.token_to_id('[PAD]')] * (seq_len - len(source.ids) - 2), dtype=torch.int64)
        ], dim=0).to(device)

        # Create source mask to ignore padding during attention
        source_mask = (source != tokenizer_src.token_to_id('[PAD]')).unsqueeze(0).unsqueeze(0).int().to(device)

        # Run encoder to get encoded representation of source sentence
        encoder_output = model.encode(source, source_mask)

        # Initialize decoder input with [SOS] token
        decoder_input = torch.empty(1, 1).fill_(tokenizer_tgt.token_to_id('[SOS]')).type_as(source).to(device)

        # Print source and target sentence if available
        if label != "": print(f"{f'ID: ':>12}{id}") 
        print(f"{f'SOURCE: ':>12}{sentence}")
        if label != "": print(f"{f'TARGET: ':>12}{label}") 
        print(f"{f'PREDICTED: ':>12}", end='')

        # Generate translation token-by-token until max length or [EOS]
        while decoder_input.size(1) < seq_len:
            # Create causal mask to prevent decoder from attending to future tokens
            decoder_mask = torch.triu(torch.ones((1, decoder_input.size(1), decoder_input.size(1))), diagonal=1).type(torch.int).type_as(source_mask).to(device)

            # Decode using encoder output and current decoder input
            out = model.decode(encoder_output, source_mask, decoder_input, decoder_mask)

            # Project decoder output to vocabulary logits and select most probable next token
            prob = model.project(out[:, -1])
            _, next_word = torch.max(prob, dim=1)

            # Append predicted token to decoder input
            decoder_input = torch.cat([decoder_input, torch.empty(1, 1).type_as(source).fill_(next_word.item()).to(device)], dim=1)

            # Print the decoded token
            print(f"{tokenizer_tgt.decode([next_word.item()])}", end=' ')

            # Stop generation if [EOS] token is predicted
            if next_word == tokenizer_tgt.token_to_id('[EOS]'):
                break

    # Decode final sequence of token IDs into readable text
    return tokenizer_tgt.decode(decoder_input[0].tolist())

# Read sentence from command-line argument or use default if none provided
translate(sys.argv[1] if len(sys.argv) > 1 else "I am not a very good a student.")
