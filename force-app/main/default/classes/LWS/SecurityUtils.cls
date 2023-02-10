/**
 * https://github.com/apex-enterprise-patterns/fflib-apex-common
 *
 * Copyright (c), FinancialForce.com, inc
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification,
 *   are permitted provided that the following conditions are met:
 *
 * - Redistributions of source code must retain the above copyright notice,
 *      this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright notice,
 *      this list of conditions and the following disclaimer in the documentation
 *      and/or other materials provided with the distribution.
 * - Neither the name of the FinancialForce.com, inc nor the names of its contributors
 *      may be used to endorse or promote products derived from this software without
 *      specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 *  ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
 *  OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL
 *  THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 *  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 *  OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 *  OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 **/

 global class SecurityUtils {
	public static Boolean bypassInternalFlsAndCrud {
		get {
			return false;
		}
	}

	@TestVisible
	private enum OperationType {
		CREATE,
		READ,
		MODIFY,
		DEL
	}

	/**
	 * Exceptions
	 */

	global virtual class SecurityException extends Exception {
		protected OperationType operation;
		protected Schema.SObjectType objectType;
	}

	global class CrudException extends SecurityException {
		private CrudException(OperationType operation, Schema.SObjectType objectType) {
			this.operation = operation;
			this.objectType = objectType;

			switch on operation {
				when CREATE {
					this.setMessage(System.Label.SecurityErrorObjectNotInsertable);
				}
				when READ {
					this.setMessage(System.Label.SecurityErrorObjectNotReadable);
				}
				when MODIFY {
					this.setMessage(System.Label.SecurityErrorObjectNotUpdateable);
				}
				when DEL {
					this.setMessage(System.Label.SecurityErrorObjectNotDeletable);
				}
			}

			this.setMessage(String.format(this.getMessage(), new List<String>{ objectType.getDescribe().getName() }));
		}
	}

	global class FlsException extends SecurityException {
		private Schema.SObjectField fieldToken;

		private FlsException(OperationType operation, Schema.SObjectType objectType, Schema.SObjectField fieldToken) {
			this.operation = operation;
			this.objectType = objectType;
			this.fieldToken = fieldToken;

			switch on operation {
				when CREATE {
					this.setMessage(System.Label.SecurityErrorFieldNotInsertable);
				}
				when READ {
					this.setMessage(System.Label.SecurityErrorFieldNotReadable);
				}
				when MODIFY {
					this.setMessage(System.Label.SecurityErrorFieldNotUpdateable);
				}
			}

			this.setMessage(
				String.format(this.getMessage(), new List<String>{ objectType.getDescribe().getName(), fieldToken.getDescribe().getName() })
			);
		}
	}

	/**
	 * Checks for entire operations (object and fields)
	 **/

	/**
	 * Create
	 */
	global static void checkInsertForPopulatedFields(SObjectType sObjType, SObject sObj) {
		checkInsert(sObj.getSObjectType(), getPopulatedFields(sObj));
	}

	global static void checkInsert(SObjectType objType, SObjectField fieldToken) {
		checkInsert(objType, new List<SObjectField>{ fieldToken });
	}

	global static void checkInsert(SObjectType objType, SObjectField fieldToken, SObjectField fieldToken2) {
		checkInsert(objType, new List<SObjectField>{ fieldToken, fieldToken2 });
	}

	global static void checkInsert(SObjectType objType, List<SObjectField> fieldTokens) {
		if (fieldTokens == null || fieldTokens.isEmpty()) {
			return;
		}
		checkObjectIsInsertable(objType);
		for (SObjectField fieldToken : fieldTokens) {
			checkFieldIsInsertable(objType, fieldToken);
		}
	}

	global static void checkInsert(SObjectType objType, Set<SObjectField> fieldTokens) {
		if (fieldTokens == null || fieldTokens.isEmpty()) {
			return;
		}
		for (SObjectField fieldToken : fieldTokens) {
			checkFieldIsInsertable(objType, fieldToken);
		}
	}

	global static void checkInsert(SObjectType objType, Set<String> fieldTokens) {
		if (fieldTokens == null || fieldTokens.isEmpty()) {
			return;
		}
		checkObjectIsInsertable(objType);
		for (String fieldToken : fieldTokens) {
			checkFieldIsInsertable(objType, fieldToken);
		}
	}

	/**
	 * Read
	 */
	global static void checkRead(SObjectType objType, String fieldName) {
		if (String.isBlank(fieldName)) {
			return;
		}
		checkRead(objType, new List<String>{ fieldName });
	}

	global static void checkRead(SObjectType objType, List<String> fieldNames) {
		if (fieldNames == null || fieldNames.isEmpty()) {
			return;
		}
		checkObjectIsReadable(objType);
		for (String fieldName : fieldNames) {
			checkFieldIsReadable(objType, fieldName);
		}
	}

	global static void checkRead(SObjectType objType, SObjectField fieldToken) {
		checkRead(objType, new List<SobjectField>{ fieldToken });
	}

	global static void checkRead(SObjectType objType, SObjectField fieldToken, SObjectField fieldToken2) {
		checkRead(objType, new List<SobjectField>{ fieldToken, fieldToken2 });
	}

	global static void checkRead(SObjectType objType, List<SObjectField> fieldTokens) {
		if (fieldTokens == null || fieldTokens.isEmpty()) {
			return;
		}
		checkObjectIsReadable(objType);
		for (SObjectField fieldToken : fieldTokens) {
			checkFieldIsReadable(objType, fieldToken);
		}
	}

	global static List<SObject> checkRead(List<SObject> objects) {
		if (bypassInternalFlsAndCrud) {
			return objects;
		}

		SObjectAccessDecision decision = Security.stripInaccessible(AccessType.READABLE, objects);
		Map<String, Set<String>> removedFields = decision.getRemovedFields();

		if (removedFields.isEmpty()) {
			return objects;
		}

		String objectName = new List<String>(removedFields.keySet())[0];
		SObjectType objectType = ((SObject) Type.forName(objectName).newInstance()).getSObjectType();

		Set<String> removedFieldsForObject = removedFields.get(objectName);
		if (removedFieldsForObject.isEmpty()) {
			throw new CrudException(OperationType.READ, objectType);
		}
		Map<String, Schema.SobjectField> result = objectType.getDescribe().fields.getMap();
		Set<String> oddFields = new Set<String>{ 'LastViewedDate', 'LastReferencedDate', 'Tier' };
		for (SobjectField fieldToken : result.values()) {
			DescribeFieldResult describeResult = fieldToken.getDescribe();
			if (!describeResult.isAccessible() && !oddFields.contains(describeResult.getName())) {
				throw new FlsException(OperationType.READ, objectType, fieldToken);
			}
		}
		return objects;
	}

	global static SObject checkRead(SObject sfObject) {
		return checkRead(new List<SObject>{ sfObject })[0];
	}

	/**
	 * Update
	 **/

	global static void checkUpdateForPopulatedFields(SObjectType sObjType, SObject sObj) {
		checkUpdate(sObj.getSObjectType(), getPopulatedFields(sObj));
	}

	global static void checkUpdate(SObjectType objType, SObjectField fieldToken) {
		checkUpdate(objType, new List<SObjectField>{ fieldToken });
	}

	global static void checkUpdate(SObjectType objType, SObjectField fieldToken, SObjectField fieldToken2) {
		checkUpdate(objType, new List<SObjectField>{ fieldToken, fieldToken2 });
	}

	global static void checkUpdate(SObjectType objType, List<SObjectField> fieldTokens) {
		if (fieldTokens == null || fieldTokens.isEmpty()) {
			return;
		}
		checkObjectIsUpdateable(objType);
		for (SObjectField fieldToken : fieldTokens) {
			checkFieldIsUpdateable(objType, fieldToken);
		}
	}

	global static void checkUpdate(SObjectType objType, String fieldName) {
		checkUpdate(objType, new Set<String>{ fieldName });
	}

	global static void checkUpdate(SObjectType objType, Set<String> fieldNames) {
		if (fieldNames == null || fieldNames.isEmpty()) {
			return;
		}
		checkObjectIsUpdateable(objType);
		for (String fieldName : fieldNames) {
			checkFieldIsUpdateable(objType, fieldName);
		}
	}

	/**
	 * Upsert
	 */

	global static void checkUpsertForPopulatedFields(SObjectType objType, SObject sObj) {
		checkUpsert(objType, getPopulatedFields(sObj));
	}

	global static void checkUpsert(SObjectType objType, SObjectField fieldToken) {
		checkUpsert(objType, new List<SobjectField>{ fieldToken });
	}

	global static void checkUpsert(SObjectType objType, SObjectField fieldToken, SObjectField fieldToken2) {
		checkUpsert(objType, new List<SobjectField>{ fieldToken, fieldToken2 });
	}

	global static void checkUpsert(SObjectType objType, List<SObjectField> fieldTokens) {
		checkInsert(objType, fieldTokens);
		checkUpdate(objType, fieldTokens);
	}
	global static void checkUpsert(SObjectType objType, Set<String> fieldTokens) {
		checkInsert(objType, fieldTokens);
		checkUpdate(objType, fieldTokens);
	}

	/**
	 * Checks for fields
	 **/

	/**
	 * Create
	 */

	global static void checkFieldIsInsertable(SObjectType objType, String fieldName) {
		checkFieldIsInsertable(objType, SecuritySObjectDescribe.getDescribe(objType).getField(fieldName));
	}

	global static void checkFieldIsInsertable(SObjectType objType, SObjectField fieldToken) {
		checkFieldIsInsertable(objType, fieldToken.getDescribe());
	}

	global static void checkFieldIsInsertable(SObjectType objType, DescribeFieldResult fieldDescribe) {
		if (byPassCheckField(fieldDescribe)){
			return;
		}

		if (!fieldDescribe.isCreateable()) {
			throw new FlsException(OperationType.CREATE, objType, fieldDescribe.getSObjectField());
		}
	}

	/**
	 * Read
	 */

	global static void checkFieldIsReadable(SObjectType objType, String fieldName) {
		checkFieldIsReadable(objType, SecuritySObjectDescribe.getDescribe(objType).getField(fieldName));
	}

	global static void checkFieldIsReadable(SObjectType objType, SObjectField fieldToken) {
		checkFieldIsReadable(objType, fieldToken.getDescribe());
	}

	global static void checkFieldIsReadable(SObjectType objType, DescribeFieldResult fieldDescribe) {
		if (bypassInternalFlsAndCrud) {
			return;
		}

		if (!fieldDescribe.isAccessible()) {
			throw new FlsException(OperationType.READ, objType, fieldDescribe.getSObjectField());
		}
	}

	/**
	 * Update
	 **/

	global static void checkFieldIsUpdateable(SObjectType objType, String fieldName) {
		if (String.isBlank(fieldName)) {
			return;
		}
		checkFieldIsUpdateable(objType, SecuritySObjectDescribe.getDescribe(objType).getField(fieldName));
	}

	global static void checkFieldIsUpdateable(SObjectType objType, SObjectField fieldToken) {
		checkFieldIsUpdateable(objType, fieldToken.getDescribe());
	}

	global static void checkFieldIsUpdateable(SObjectType objType, DescribeFieldResult fieldDescribe) {
		if (byPassCheckField(fieldDescribe)){
			return;
		}

		if (!fieldDescribe.isUpdateable()) {
			throw new FlsException(OperationType.MODIFY, objType, fieldDescribe.getSObjectField());
		}
	}

	private static Boolean byPassCheckField(DescribeFieldResult fieldDescribe){
		if (bypassInternalFlsAndCrud) {
			return true;
		}

		if (!fieldDescribe.isPermissionable()) {
			return true;
		}
		
		if (fieldDescribe.getType() == DisplayType.ADDRESS) {
			return true;
		}

		if (!fieldDescribe.getReferenceTo().isEmpty()){
			return true;
		}

		if (fieldDescribe.isCalculated()) {
			return true;
		}

		return false;
	}

	/**
	 * Checks for objects
	 **/
	global static void checkObjectIsUpsertable(SObjectType objType) {
		checkObjectIsInsertable(objType);
		checkObjectIsUpdateable(objType);
	}

	global static void checkObjectIsInsertable(SObjectType objType) {
		if (bypassInternalFlsAndCrud) {
			return;
		}

		if (!objType.getDescribe().isCreateable()) {
			throw new CrudException(OperationType.CREATE, objType);
		}
	}

	global static void checkObjectIsReadable(SObjectType objType) {
		if (bypassInternalFlsAndCrud) {
			return;
		}

		if (!objType.getDescribe().isAccessible()) {
			throw new CrudException(OperationType.READ, objType);
		}
	}

	global static void checkObjectIsUpdateable(SObjectType objType) {
		if (bypassInternalFlsAndCrud) {
			return;
		}

		if (!objType.getDescribe().isUpdateable()) {
			throw new CrudException(OperationType.MODIFY, objType);
		}
	}

	global static void checkObjectIsDeletable(Id objectId) {
		checkObjectIsDeletable(objectID.getSobjectType());
	}

	global static void checkObjectIsDeletable(SObjectType objType) {
		if (bypassInternalFlsAndCrud) {
			return;
		}

		if (!objType.getDescribe().isDeletable()) {
			throw new CrudException(OperationType.DEL, objType);
		}
	}

	private static Set<String> getPopulatedFields(SObject sObj) {
		Set<String> returnValue = new Set<String>();
		Map<String, Object> fieldsToValue = sObj.getPopulatedFieldsAsMap();
		for (String fieldName : fieldsToValue.keySet()) {
			returnValue.add(fieldName);
		}
		return returnValue;
	}
}
