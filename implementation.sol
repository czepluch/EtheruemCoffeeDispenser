contract ClipcardMachine {
	
	struct Clipcard {
		uint amountOfClips;
		bytes32 name;
	}

	mapping (address => Clipcard) clipcards;

	address issuer;
	address machine;
	uint price;
	uint newClips;
	
	function ClipcardMachine(address machineAddress) {
		issuer = msg.sender;
		machine = machineAddress;
		price = 1000000000000000;
		newClips = 10;
	}
	
	function deductClip(address beneficiary) {
		clipcards[beneficiary].amountOfClips -= 1;
	}
	
	function addClip(address beneficiary) {
		clipcards[beneficiary].amountOfClips += 1;
	}

	function buyClipcard(bytes32 name) returns (bool success) {
		
		if(msg.value < price || name == ""){
			return false;
		}
		
		Clipcard c = clipcards[msg.sender]; // assigns reference
	    c.name = name;
	    c.amountOfClips += newClips;
				
		return true;
	}

	function useClip() returns (bool success){
		if(clipcards[msg.sender].name == "" || clipcards[msg.sender].amountOfClips < 1) {
			return false;
		}
		deductClip(msg.sender);

		Machine mach = Machine(machine);
		bool open = mach.open();
		if(!open) {addClip(msg.sender);}

		return true;
	}
	
	function setPrice(uint p) {
		if(msg.sender == issuer && p >= 0)
			price = p;
	}
	
	function setMachine(address a) {
		if(msg.sender == issuer)
			machine = a;
	}
	
	function setIssuer(address a) {
		if(msg.sender == issuer)
			issuer = a;
	}
	
	function emptyMachine(){
		if(msg.sender == issuer)
			issuer.send(this.balance);
	}
	
	function commitSuicide(){
		if(msg.sender == issuer)
			suicide(issuer);
	}
	
	function checkBalance() returns (uint balance) {
		Clipcard c = clipcards[msg.sender];
		balance = c.amountOfClips;
		return balance;
	}

	function getName() returns (bytes32 name){
		Clipcard c = clipcards[msg.sender];
		name = c.name;
		return name;
	}
}

contract Machine {
	/**~\label{line:modular_machine}~
	  * An artificial representation of a Machine that gets opened when a punch is registered
	  *
	  */
	address issuer;
	address owner;
	uint public openTill;
	uint public cupsPoured;

	// Empty constructor
	function Machine(){
		owner = msg.sender;
	}

	function setIssuer(address addr){
		if(msg.sender == owner) {issuer = addr;}
	}

	function open() returns (bool result) {
		if(msg.sender != issuer) {return false;}
		if(cupsPoured == 10) {
			cupsPoured = 0;
			return false;
		}
		if(block.number > openTill) {openTill = block.number + 2;}
		else {openTill += 2;}
		return true;
	}

	function isOpen() returns (bool open) {
		return (block.number < openTill);
	}
}