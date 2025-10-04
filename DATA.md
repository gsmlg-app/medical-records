# **Medical Records: Data Structure and Management Plan (Flutter with Drift) \- Final Version**

This document details the final database design for the application. The design uses a fully normalized relational model, creating independent and interconnected tables for hospitals, departments, doctors, treatments, visits, and related resources.

### **Part 1: Basic Data Tables**

#### **1.1 Hospitals Table (Hospitals) \- (Updated)**

Stores basic hospital information and includes a list of department IDs it owns.

* **id**: (Integer) Primary key.  
* **name**: (String) Hospital name, must be unique.  
* **address**: (String) Address (optional).  
* **type**: (**String, New**) The hospital's type (e.g., "General Hospital," "Specialty Hospital," "Private Hospital"), optional.  
* **level**: (**String, New**) The hospital's level (e.g., "Class A Grade 3," "Class B Grade 2"), optional.  
* **departmentIds**: (**Text**) **Core Change Field**. Used to store the list of all department IDs owned by this hospital.  
  * **Storage Format:** The list will be encoded as a JSON string. For example: "\[10, 11, 12\]".  
  * **Drift Implementation:** We will create a TypeConverter to automatically convert between Dart code (List\<int\>) and the database (String).  
* **createdAt**, **updatedAt**: (DateTime) Timestamps.

#### **1.2 Departments Table (Departments)**

Stores global department types, not directly associated with any specific hospital.

* **id**: (Integer) Primary key.  
* **name**: (String) Name of the department (e.g., "Cardiology"), this field should be unique.  
* **category**: (String) Category of the department (e.g., "Clinical Department," "Medical Technology Department"), optional.

#### **1.3 Doctors Table (Doctors)**

Stores doctor information and acts as the link between hospitals and departments.

* **id**: (Integer) Primary key.  
* **hospitalId**: (Integer, **Foreign Key**) References the id in the Hospitals table.  
* **departmentId**: (Integer, **Foreign Key**) References the id in the Departments table.  
* **name**: (String) Doctor's name.  
* **level**: (String) Doctor's level (optional).  
* **createdAt**, **updatedAt**: (DateTime) Timestamps.

### **Part 2: Core Medical Record Tables**

#### **2.1 Top-Level Treatment Records (Treatments)**

* **id**: (Integer) Primary key.  
* **title**: (String) Treatment title.  
* **diagnosis**: (String) Diagnosis information.  
* **startDate**: (DateTime) Start date.  
* **endDate**: (DateTime) End date (optional, as the treatment may still be ongoing).  
* **createdAt**, **updatedAt**: (DateTime) Timestamps.

#### **2.2 Single Visit Records (Visits)**

* **id**: (Integer) Primary key.  
* **treatmentId**: (Integer, **Foreign Key**) References Treatments.  
* **category**: (Enum VisitCategory) Outpatient or Inpatient.  
* **date**: (DateTime) Visit date.  
* **details**: (String) Details.  
* **hospitalId**: (Integer, **Foreign Key**, optional) References Hospitals.  
* **departmentId**: (Integer, **Foreign Key**, optional) References Departments.  
* **doctorId**: (Integer, **Foreign Key**, optional) References Doctors.  
* **informations**: (**Text**, optional) A JSON field for storing additional, unstructured data for future use.  
* **createdAt**, **updatedAt**: (DateTime) Timestamps.

### **Part 3: Resource Management Table**

#### **3.1 Resources Table (Resources)**

Stores metadata for images or other files associated with a single visit.

* **id**: (Integer) Primary key.  
* **visitId**: (Integer, **Foreign Key**) References Visits.  
* **type**: (Enum ResourceType) Resource type.  
* **filePath**: (String) The file's local storage path on the device. **Storage format is: \<basedir\>/\<visitId\>/\<uuid\>.\<suffix\>**, where \<basedir\> is the app's base storage directory, \<visitId\> is the associated visit ID, \<uuid\> is a unique identifier, and \<suffix\> is the file extension.  
* **notes**: (String) Notes (optional).  
* **createdAt**, **updatedAt**: (DateTime) Timestamps.