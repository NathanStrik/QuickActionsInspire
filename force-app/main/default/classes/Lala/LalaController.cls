public with sharing class LalaController {
    @AuraEnabled
	public static void addLala(Id recordId) {
		if (String.isBlank(recordId))
			return;
		Contact innocentVictim = [SELECT Id, Email FROM Contact	WHERE Id = :recordId];

		try {
			innocentVictim.Email = 'Lala.' + innocentVictim.Email;
			update innocentVictim;
		} catch (DMLException e) {
			throw new AuraHandledException(e.getDmlMessage(0));
		} catch (Exception ex) {
			throw new AuraHandledException('Whoopsie!');
		}
	}
}
