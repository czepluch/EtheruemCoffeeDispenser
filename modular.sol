contract IsManaged {
	/**~\label{line:modular_ismanaged}~
	  * Supercontract for all contracts that are managed by the Manager
	  */
	address manager;

	// Set the manager for this contract
	function setManager(address managerAddr) returns (bool result){
		// Set a manager if none is set, or if the sender is the current manager
		if(manager != 0x0 && msg.sender != manager) {return false;}
		// Set the manager address
		manager = managerAddr;
	}

	// Kill the contract and send the funds to the manager
	function commitSuicide(){
		// Kill the contract and send funds to manager
		if(msg.sender == manager) {suicide(manager);}
	}
}

contract Issuer is IsManaged{
	/** ~\label{line:modular_issuer}~
	  * The Issuer is the main access point for this DApp.
	  * It utilises the AssetHolder, Settings, Machine and NameDb directly and the PunchDb indirectly.
	  * It is the only contract that should have a GUI.
	  */
	address owner;

	// Constructor that sets the owner
	function Issuer() {
		owner = msg.sender;
	}

	// Function for buying a punch card. Accesses the AssetHolder and the NameDb
	function buyCard(bytes32 name) {
		if(manager != 0x0){
			// Get address of the assetHolder
			address assetHolder = Manager(manager).getComponent("assetHolder");
	
			// Try to restock card
			bool goon = AssetHolder(assetHolder).restockCard(msg.sender);
			// If restock failed, return
			if(!goon) {return;}
	
			// Get address of nameDb
			address nameDb = Manager(manager).getComponent("nameDb");
			// Set the name in the nameDb
			NameDb(nameDb).setName(msg.sender, name);
		}
	}

	// Function for punching a card. Accesses the AssetHolder and the Machine
	function punchCard() {
		if(manager != 0x0) {
			// Get address of assetHolder
			address assetHolder = Manager(manager).getComponent("assetHolder");

			// Try to punch card
			bool punched = AssetHolder(assetHolder).punchCard(msg.sender);
			// If punch failed, return
			if(!punched) {return;}

			// Get address of machine
			address machine = Manager(manager).getComponent("machine");
			bool opened = Machine(machine).open();
			if(!opened) {
				bool unpunched = AssetHolder(assetHolder).unpunchCard(msg.sender);
			}
		}
	}

	// Function for setting the price. Accesses Settings
	function setPrice(uint value) {
		// Make sure sender is owner
		if(msg.sender != owner) {return;}
		// Make sure theres a manager
		if(manager != 0x0) {
			// Get the settings
			address settings = Manager(manager).getComponent("settings");
			Settings(settings).addSetting("price", value);
		}
	}

	// Function for getting the price. Accesses Settings
	function getPrice() returns (uint value) {
		// Make sure theres a manager
		if(manager != 0x0) {
			// Get the settings
			address settings = Manager(manager).getComponent("settings");
			return Settings(settings).getSetting("price");
		}
		return 0;
	}

	// Function for setting the add amount of punches. Accesses Settings
	function setAddAmount(uint value) {
		// Make sure sender is owner
		if(msg.sender != owner) {return;}
		// Make sure theres a manager
		if(manager != 0x0) {
			// Get the settings
			address settings = Manager(manager).getComponent("settings");
			Settings(settings).addSetting("addAmount", value);
		}
	}

	// Function for getting the add amount of punches. Accesses Settings
	function getAddAmount() returns (uint value) {
		// Make sure theres a manager
		if(manager != 0x0) {
			// Get the settings
			address settings = Manager(manager).getComponent("settings");
			return Settings(settings).getSetting("addAmount");
		}
		return 0;
	}

	// Function for setting the punch amount of punches. Accesses Settings
	function setPunchAmount(uint value) {
		// Make sure sender is owner
		if(msg.sender != owner) {return;}
		// Make sure theres a manager
		if(manager != 0x0) {
			// Get the settings
			address settings = Manager(manager).getComponent("settings");
			Settings(settings).addSetting("punchAmount", value);
		}
	}

	// Function for getting the punch amount of punches. Accesses Settings
	function getPunchAmount() returns (uint value) {
		// Make sure theres a manager
		if(manager != 0x0) {
			// Get the settings
			address settings = Manager(manager).getComponent("settings");
			return Settings(settings).getSetting("punchAmount");
		}
		return 0;
	}

	// Function for getting the punch balance. Accesses the AssetHolder
	function getBalance() returns (uint value) {
		// Make sure there's a manager
		if(manager != 0x0) {
			// Get the assetHolder
			address assetHolder = Manager(manager).getComponent("assetHolder");

			return AssetHolder(assetHolder).getBalance(msg.sender);
		}
		return 0;
	}

	// Function for getting the name. Accesses the NameDb
	function getName() returns (bytes32 name) {
		// Make sure there's a manager
		if(manager != 0x0) {
			// Get the assetHolder
			address nameDb = Manager(manager).getComponent("nameDb");

			return NameDb(nameDb).getName(msg.sender);
		}
		return "This issuer has no manager";
	}

	// Fucntion to set the owner
	function setOwner(address addr){
		if(msg.sender == owner) {owner = addr;}
	}

	// Function to empty the AssetHolder. Accesses the AssetHolder
	function empty(){
		if(msg.sender != owner) {return;}
		// Make sure there's a manager
		if(manager != 0x0) {
			// Get the address of the Asset Holder
			address assetHolder = Manager(manager).getComponent("assetHolder");

			AssetHolder(assetHolder).empty(msg.sender);
		}
	}
}

contract Machine is IsManaged {
	/**~\label{line:modular_machine}~
	  * An artificial representation of a Machine that gets opened when a punch is registered
	  *
	  */

	uint public openTill;
	uint public cupsPoured;

	// Empty constructor
	function Machine(){}

	function open() returns (bool result) {
		if(manager != 0x0) {
			address issuer = Manager(manager).getComponent("issuer");
			if(msg.sender != issuer) {return false;}
			if(cupsPoured == 10) {
				cupsPoured = 0;
				return false;
			}
			if(block.number > openTill) {openTill = block.number + 2;}
			else {openTill += 2;}
			return true;
		}
	}

	function isOpen() returns (bool open) {
		return (block.number < openTill);
	}
}



contract AssetHolder is IsManaged {
	/**~\label{line:modular_assetholder}~
	  * The AssetHolder handles the logic related to the punch cards and holds the value of the system
	  * Can only be modified by a specified Issuer
	  */
	// Empty constructor
	function AssetHolder(){}

	// Restock a card
	function restockCard(address addr) returns (bool result) {
		if(manager != 0x0) {
			// Check that the sender is the issuer
			address issuer = Manager(manager).getComponent("issuer");
			if(msg.sender != issuer) {return false;}

			// Get the settings
			address settings = Manager(manager).getComponent("settings");
			// Get the price
			uint price = Settings(settings).getSetting("price");
			// Get the add amount
			uint amount = Settings(settings).getSetting("addAmount");
			// Return if a setting is not set
			if(price == 0 || amount == 0) {return false;}

			// If the value of the message is too low, return the value and fail
			if(msg.value < price) {
				addr.send(msg.value);
				return false;
			}

			// Get the punch db
			address punchDb = Manager(manager).getComponent("punchDb");

			// Add the amount to the db.
			bool add = PunchDb(punchDb).add(addr, amount);
			return add;
		}
	}

	// Punch a card
	function punchCard(address addr) returns (bool result) {
		if(manager != 0x0) {
			// Check that the sender is the issuer
			address issuer = Manager(manager).getComponent("issuer");
			if(msg.sender != issuer) {return false;}

			// Get the settings
			address settings = Manager(manager).getComponent("settings");
			// Get the punch amount
			uint amount = Settings(settings).getSetting("punchAmount");
			// Return if the setting is not set
			if(amount == 0) {return false;}

			// Get the punch db
			address punchDb = Manager(manager).getComponent("punchDb");

			// Punch the card
			bool pun = PunchDb(punchDb).punch(addr, amount);
			return pun;
		}
	}

	// Unpunch a card
	function unpunchCard(address addr) returns (bool result) {
		if(manager != 0x0) {
			// Check that the sender is the issuer
			address issuer = Manager(manager).getComponent("issuer");
			if(msg.sender != issuer) {return false;}

			// Get the settings
			address settings = Manager(manager).getComponent("settings");
			// Get the punch amount
			uint amount = Settings(settings).getSetting("punchAmount");
			// Return if the setting is not set
			if(amount == 0) {return false;}

			// Get the punch db
			address punchDb = Manager(manager).getComponent("punchDb");

			// Unpunch the card
			bool add = PunchDb(punchDb).add(addr, amount);
			return add;
		}
	}

	// Get the balance
	function getBalance(address addr) returns (uint balance) {
		if(manager != 0x0) {
			// Get the punch db
			address punchDb = Manager(manager).getComponent("punchDb");
			uint bal = PunchDb(punchDb).getBalance(addr);
			return bal;
		}
		return 0;
	}

	// Empty the Asset Holder
	function empty(address addr){
		if(manager != 0x0) {
			// Check that the sender is the issuer
			address issuer = Manager(manager).getComponent("issuer");
			if(msg.sender != issuer) {return;}

			addr.send(this.balance);
		}
	}
}

contract Settings is IsManaged {
	/**~\label{line:modular_settings}~
	  * Settings database
	  * Can only be modified by a specified Issuer
	  */
	mapping (bytes32 => uint) settings;

	function Settings() {}

	function addSetting(bytes32 name, uint setting){
		// Make sure there's a manager
		if(manager != 0x0){
			// Get the issuer
			address controller = Manager(manager).getComponent("issuer");
			// If the issuer sent the message, update the setting
			if(msg.sender == controller) {settings[name] = setting;}
		}
	}

	function getSetting(bytes32 name) returns (uint setting){		
		return settings[name];
	}
}

contract PunchDb is IsManaged {
	/**~\label{line:modular_punchdb}~
	  * Database to handle punches on punch cards
	  * The PunchDb can only be modified from a specified AssetHolder
	  */
	mapping (address => uint) punchDb;

	// Empty constructor
	function PunchDb(){}

	// Adds punches to a punch card
	function add(address addr, uint newClips) returns (bool result) {
		// Make sure there's a manager
		if(manager != 0x0){
			// Get the controller of the PunchDb
			address controller = Manager(manager).getComponent("assetHolder");
			// If the controller sent the message, update the punch card
			if(msg.sender == controller) {
				punchDb[addr] += newClips;
				return true;
			}
		}
		return false;
	}

	// Deduct punches from a punch card if possible
	function punch(address addr, uint punchClips) returns (bool result) {
		// If the balance is too low, return
		if(punchDb[addr] < punchClips) {return false;}
		// Make sure there's a manager
		if(manager != 0x0){
			// Get the controller of the PunchDb
			address controller = Manager(manager).getComponent("assetHolder");
			// If the controller sent the message, update the punch card
			if(msg.sender == controller) {
				punchDb[addr] -= punchClips;
				return true;
			}
		}

		return false;
	}

	// Gets the balance of a punch card
	function getBalance(address addr) returns (uint balance) {
		return punchDb[addr];
	}
}

contract NameDb is IsManaged {
	/**~\label{line:modular_namedb}~
	  * Database to handle names in the system
	  * The NameDb can only be modified by a specified Issuer
	  */
	mapping (address => bytes32) nameDb;

	// Empty constructor
	function NameDb(){}

	// Set a name in the database
	function setName(address addr, bytes32 name){
		// Make sure there's a manager
		if(manager != 0x0){
			// Get the controller of the NameDb
			address controller = Manager(manager).getComponent("issuer");
			// If the controller sent the message, update the name
			if(msg.sender == controller) {nameDb[addr] = name;}
		}
	}

	// Get a name from the database
	function getName(address addr) returns (bytes32 name) {
		// Make sure there's a manager
		if(manager != 0x0) {
			// Get the controller og the NameDb
			address controller = Manager(manager).getComponent("issuer");
			// If the controller sent the message, return the name
			if(msg.sender == controller) {return nameDb[addr];}
		}

		return "";
	}
}

contract Manager {
	/**~\label{line:modular_manager}~
	  * The manager contract is responsible for handling all the components of the Punch Card Issuer system
	  */
	address owner;
	mapping (bytes32 => address) contracts;

	// Constructor for the Manager
	function Manager(){
		owner = msg.sender;
	}

	// Adds a component to the system
	function addComponent(bytes32 name, address comp) returns (bool result){
		// If sender is not owner, fail
		if(msg.sender != owner)	{return false;}

		// Try to set this as manager in contract
		IsManaged managed = IsManaged(comp);
		bool sm = managed.setManager(address(this));

		// If this fails, fail
		if(!sm)	{return false;}

		// Store in mapping
		contracts[name] = comp;
		return true;
	}

	// Removes a component from the system
	function removeComponent(bytes32 name) returns (bool result){
		// If the component is not set, fail
		if(contracts[name] == 0x0) {return false;}
		// If the sender is not the owner, fail
		if(msg.sender != owner) {return false;}

		// Set the contract to nothing
		contracts[name] = 0x0;
	}

	// Kills a component by making it commit suicide
	function killComponent(bytes32 name) {
		if(owner != msg.sender) {return;}
		IsManaged(contracts[name]).commitSuicide();
		owner.send(this.balance);
		contracts[name] = 0x0;
	}

	// Get a component
	function getComponent(bytes32 name) returns (address addr){
		// Method to check that all parts have been set
		return contracts[name];
	}

	// Change the owner of the Manager
	function setOwner(address addr){
		if(msg.sender == owner) {owner = addr;}
	}

}