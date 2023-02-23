/**
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

 public class SecuritySObjectDescribe {
	private Schema.SObjectType token;
	private Schema.SObjectField nameField;

	private Schema.DescribeSObjectResult describe {
		get {
			if (describe == null) {
				describe = token.getDescribe();
			}

			return describe;
		}
		set;
	}

	private Map<String, Schema.SObjectField> fields {
		get {
			if (fields == null) {
				fields = describe.fields.getMap();
			}

			return fields;
		}
		set;
	}

	private Map<String, Schema.FieldSet> fieldSets {
		get {
			if (fieldSets == null) {
				fieldSets = describe.fieldSets.getMap();
			}

			return fieldSets;
		}
		set;
	}

	private FieldsMap wrappedFields {
		get {
			if (wrappedFields == null) {
				wrappedFields = new FieldsMap(this.fields);
			}

			return wrappedFields;
		}
		set;
	}

	private SecuritySObjectDescribe(Schema.SObjectType token) {
		if (token == null) {
			throw new InvalidDescribeException('Invalid SObject type: null');
		}

		this.token = token;
		instanceCache.put(String.valueOf(token).toLowerCase(), this);
	}

	public Schema.SObjectType getSObjectType() {
		return token;
	}

	public Schema.SObjectField getField(String name) {
		return this.getField(name, true);
	}

	public Schema.SObjectField getField(String fieldName, Boolean implyNamespace) {
		Schema.SObjectField result = wrappedFields.get(
			(fieldName.endsWithIgnoreCase('__r') ? (fieldName.removeEndIgnoreCase('__r') + '__c') : fieldName),
			implyNamespace
		);

		if (result == null) {
			result = wrappedFields.get(fieldName + 'Id', implyNamespace);
		}

		return result;
	}

	public Schema.SObjectField getNameField() {
		if (nameField == null) {
			for (Schema.SObjectField field : wrappedFields.values()) {
				if (field.getDescribe().isNameField()) {
					nameField = field;
					break;
				}
			}
		}

		return nameField;
	}

	public Schema.DescribeSObjectResult getDescribe() {
		return describe;
	}

	public Map<String, Schema.SObjectField> getFieldsMap() {
		return fields;
	}

	public FieldsMap getFields() {
		return wrappedFields;
	}

	public Map<String, Schema.FieldSet> getFieldSetsMap() {
		return fieldSets;
	}

	private static Map<String, Schema.SObjectType> rawGlobalDescribe {
		get {
			if (rawGlobalDescribe == null) {
				rawGlobalDescribe = Schema.getGlobalDescribe();
			}

			return rawGlobalDescribe;
		}
		set;
	}

	private static GlobalDescribeMap wrappedGlobalDescribe {
		get {
			if (wrappedGlobalDescribe == null) {
				wrappedGlobalDescribe = new GlobalDescribeMap(rawGlobalDescribe);
			}

			return wrappedGlobalDescribe;
		}
		set;
	}

	private static Map<String, SecuritySObjectDescribe> instanceCache {
		get {
			if (instanceCache == null) {
				instanceCache = new Map<String, SecuritySObjectDescribe>();
			}

			return instanceCache;
		}
		set;
	}

	public static SecuritySObjectDescribe getDescribe(String sObjectName) {
		if (String.isBlank(sObjectName)) {
			return null;
		}

		SecuritySObjectDescribe result = instanceCache.get(sObjectName.toLowerCase());
		if (result != null) {
			return result;
		}

		Schema.SObjectType token = wrappedGlobalDescribe.get(sObjectName.toLowerCase());
		if (token == null) {
			return null;
		}

		return new SecuritySObjectDescribe(token);
	}

	public static SecuritySObjectDescribe getDescribe(Schema.SObjectType token) {
		if (token == null) {
			return null;
		}

		SecuritySObjectDescribe result = instanceCache.get(String.valueOf(token).toLowerCase());
		if (result != null) {
			return result;
		}

		return new SecuritySObjectDescribe(token);
	}

	public static SecuritySObjectDescribe getDescribe(Schema.DescribeSObjectResult nativeDescribe) {
		if (nativeDescribe == null) {
			return null;
		}

		SecuritySObjectDescribe result = instanceCache.get(nativeDescribe.getName().toLowerCase());
		if (result != null) {
			return result;
		}

		return new SecuritySObjectDescribe(nativeDescribe.getSObjectType());
	}

	public static SecuritySObjectDescribe getDescribe(SObject instance) {
		if (instance == null) {
			return null;
		}

		return getDescribe(instance.getSObjectType());
	}

	public static Map<String, SObjectType> getRawGlobalDescribe() {
		return rawGlobalDescribe;
	}

	public static GlobalDescribeMap getGlobalDescribe() {
		return wrappedGlobalDescribe;
	}

	public static void flushCache() {
		rawGlobalDescribe = null;
		instanceCache = null;
	}

	private abstract class NamespacedAttributeMap {
		@TestVisible
		protected String currentNamespace;
		protected Map<String, Object> values;

		protected NamespacedAttributeMap(Map<String, Object> values) {
			currentNamespace = SecuritySObjectDescribe.class
				.getName()
				.substringBefore('SecuritySObjectDescribe')
				.removeEnd('.')
				.toLowerCase();
			this.values = values;
		}

		protected NamespacedAttributeMap() {
			this(new Map<String, Object>());
		}

		protected virtual Object getObject(String name) {
			return this.getObject(name, true);
		}

		protected virtual Object getObject(String name, Boolean implyNamespace) {
			if (name == null) {
				return null;
			}

			String preferredValue = ((implyNamespace ? currentNamespace + '__' : '') + name).toLowerCase();
			if (values.containsKey(preferredValue)) {
				return values.get(preferredValue);
			} else if (implyNamespace) {
				return values.get(name.toLowerCase());
			} else {
				return null;
			}
		}

		public virtual Boolean containsKey(String name) {
			return this.containsKey(name, true);
		}

		public virtual Boolean containsKey(String name, Boolean implyNamespace) {
			if (name == null) {
				return null;
			}

			String preferredValue = ((implyNamespace ? currentNamespace + '__' : '') + name).toLowerCase();
			return (values.containsKey(preferredValue) || implyNamespace && values.containsKey(name.toLowerCase()));
		}

		public virtual Integer size() {
			return values.size();
		}

		public virtual Set<String> keySet() {
			return this.keySet(false);
		}

		public virtual Set<String> keySet(Boolean implyNamespace) {
			if (!implyNamespace) {
				return values.keySet();
			}

			Set<String> result = new Set<String>();
			for (String key : values.keySet()) {
				result.add(key.removeStartIgnoreCase(currentNamespace + '__'));
			}

			return result;
		}
	}

	public class FieldsMap extends NamespacedAttributeMap {
		@TestVisible
		private FieldsMap(Map<String, Schema.SObjectField> values) {
			super(values);
		}

		public Schema.SObjectField get(String name) {
			return this.get(name, true);
		}
		public Schema.SObjectField get(String name, Boolean implyNamespace) {
			return (Schema.SObjectField) this.getObject(name, implyNamespace);
		}
		public List<Schema.SObjectField> values() {
			return (List<Schema.SObjectField>) values.values();
		}
	}

	public class GlobalDescribeMap extends NamespacedAttributeMap {
		@TestVisible
		private GlobalDescribeMap(Map<String, Schema.SObjectType> values) {
			super(values);
		}

		public Schema.SObjectType get(String name) {
			return this.get(name, true);
		}
		public Schema.SObjectType get(String name, Boolean implyNamespace) {
			return (Schema.SObjectType) this.getObject(name, implyNamespace);
		}
		public List<Schema.SObjectType> values() {
			return (List<Schema.SObjectType>) values.values();
		}
	}

	public abstract class DescribeException extends Exception {
	}

	public class DuplicateDescribeException extends DescribeException {
	}

	public class InvalidDescribeException extends DescribeException {
	}
}
