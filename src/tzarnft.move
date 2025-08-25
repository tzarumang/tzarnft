module tzarnft::nft {
    use sui::object::{Self, UID};
    use sui::transfer;
    use sui::tx_context::{Self, TxContext};
    use std::string::{Self, String};
    use sui::url::{Self, Url};
    use sui::event;

    // Error codes
    const ENotOwner: u64 = 0;
    const EInvalidTokenId: u64 = 1;

    // NFT struct - represents a single NFT
    struct SimpleNFT has key, store {
        id: UID,
        name: String,
        description: String,
        image_url: Url,
        creator: address,
        token_id: u64,
    }

    // Collection struct - manages the NFT collection
    struct NFTCollection has key {
        id: UID,
        name: String,
        description: String,
        creator: address,
        total_supply: u64,
        max_supply: u64,
    }

    // Mint capability - controls who can mint NFTs
    struct MintCap has key, store {
        id: UID,
        collection_id: address,
    }

    // Events
    struct NFTMinted has copy, drop {
        nft_id: address,
        creator: address,
        name: String,
        token_id: u64,
    }

    struct CollectionCreated has copy, drop {
        collection_id: address,
        creator: address,
        name: String,
        max_supply: u64,
    }

    // Initialize function - called when the module is published
    fun init(ctx: &mut TxContext) {
        // Create the initial collection
        create_collection(
            string::utf8(b"TZAR NFT Collection"),
            string::utf8(b"Official TZAR NFT collection on Sui"),
            1000, // max supply
            ctx
        );
    }

    // Create a new NFT collection
    public entry fun create_collection(
        name: String,
        description: String,
        max_supply: u64,
        ctx: &mut TxContext
    ) {
        let collection = NFTCollection {
            id: object::new(ctx),
            name,
            description,
            creator: tx_context::sender(ctx),
            total_supply: 0,
            max_supply,
        };

        let mint_cap = MintCap {
            id: object::new(ctx),
            collection_id: object::uid_to_address(&collection.id),
        };

        event::emit(CollectionCreated {
            collection_id: object::uid_to_address(&collection.id),
            creator: tx_context::sender(ctx),
            name: collection.name,
            max_supply,
        });

        transfer::transfer(mint_cap, tx_context::sender(ctx));
        transfer::share_object(collection);
    }

    // Mint a new NFT
    public entry fun mint_nft(
        collection: &mut NFTCollection,
        _mint_cap: &MintCap,
        name: String,
        description: String,
        image_url: vector<u8>,
        recipient: address,
        ctx: &mut TxContext
    ) {
        assert!(collection.total_supply < collection.max_supply, EInvalidTokenId);

        collection.total_supply = collection.total_supply + 1;

        let nft = SimpleNFT {
            id: object::new(ctx),
            name,
            description,
            image_url: url::new_unsafe_from_bytes(image_url),
            creator: tx_context::sender(ctx),
            token_id: collection.total_supply,
        };

        event::emit(NFTMinted {
            nft_id: object::uid_to_address(&nft.id),
            creator: tx_context::sender(ctx),
            name: nft.name,
            token_id: nft.token_id,
        });

        transfer::public_transfer(nft, recipient);
    }

    // Batch mint NFTs
    public entry fun batch_mint(
        collection: &mut NFTCollection,
        mint_cap: &MintCap,
        names: vector<String>,
        descriptions: vector<String>,
        image_urls: vector<vector<u8>>,
        recipients: vector<address>,
        ctx: &mut TxContext
    ) {
        let length = std::vector::length(&names);
        assert!(length == std::vector::length(&descriptions), EInvalidTokenId);
        assert!(length == std::vector::length(&image_urls), EInvalidTokenId);
        assert!(length == std::vector::length(&recipients), EInvalidTokenId);

        let i = 0;
        while (i < length) {
            mint_nft(
                collection,
                mint_cap,
                *std::vector::borrow(&names, i),
                *std::vector::borrow(&descriptions, i),
                *std::vector::borrow(&image_urls, i),
                *std::vector::borrow(&recipients, i),
                ctx
            );
            i = i + 1;
        };
    }

    // Transfer NFT to another address
    public entry fun transfer_nft(
        nft: SimpleNFT,
        recipient: address,
        _ctx: &mut TxContext
    ) {
        transfer::public_transfer(nft, recipient);
    }

    // Burn an NFT
    public entry fun burn_nft(
        nft: SimpleNFT,
        _ctx: &mut TxContext
    ) {
        let SimpleNFT {
            id,
            name: _,
            description: _,
            image_url: _,
            creator: _,
            token_id: _,
        } = nft;
        object::delete(id);
    }

    // Update NFT metadata (only by creator)
    public entry fun update_nft_metadata(
        nft: &mut SimpleNFT,
        new_name: String,
        new_description: String,
        new_image_url: vector<u8>,
        ctx: &mut TxContext
    ) {
        assert!(nft.creator == tx_context::sender(ctx), ENotOwner);
        nft.name = new_name;
        nft.description = new_description;
        nft.image_url = url::new_unsafe_from_bytes(new_image_url);
    }

    // Getter functions
    public fun get_nft_name(nft: &SimpleNFT): String {
        nft.name
    }

    public fun get_nft_description(nft: &SimpleNFT): String {
        nft.description
    }

    public fun get_nft_image_url(nft: &SimpleNFT): Url {
        nft.image_url
    }

    public fun get_nft_creator(nft: &SimpleNFT): address {
        nft.creator
    }

    public fun get_nft_token_id(nft: &SimpleNFT): u64 {
        nft.token_id
    }

    public fun get_collection_info(collection: &NFTCollection): (String, String, address, u64, u64) {
        (collection.name, collection.description, collection.creator, collection.total_supply, collection.max_supply)
    }

    // Check if an address owns a specific NFT
    public fun is_nft_owner(nft: &SimpleNFT, owner: address): bool {
        // Note: In actual implementation, you'd need to check the object ownership
        // This is a placeholder for demonstration
        nft.creator == owner
    }
}