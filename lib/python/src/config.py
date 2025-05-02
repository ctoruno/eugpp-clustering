import getpass

def get_EUpath():
    """
    Get the path to the EUPATH directory.
    
    Returns:
        str: The path to the EUPATH directory.
    """

    if getpass.getuser() == "carlostoruno":
        return "/Users/carlostoruno/OneDrive - World Justice Project/EU Subnational/EU-S Data"
    else:
        raise Exception("User not recognized. Please set the EUPATH for this user in the 'config.py' file.")