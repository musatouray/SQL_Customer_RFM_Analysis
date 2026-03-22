# SQL Customer RFM Analysis

A data analysis project that uses SQL and Python to perform **RFM (Recency, Frequency, Monetary)** analysis on customer data.

---

## Getting Started

### Prerequisites

- Python 3.8 or higher
- `pip` (comes bundled with Python)

---

## Setting Up a Virtual Environment

A virtual environment keeps project dependencies isolated from your global Python installation.

### 1. Create the virtual environment

Open a terminal in this project folder and run:

```bash
python -m venv venv
```

This creates a folder named `venv/` inside the project directory.

---

### 2. Activate the virtual environment

**macOS / Linux:**

```bash
source venv/bin/activate
```

**Windows (Command Prompt):**

```cmd
venv\Scripts\activate.bat
```

**Windows (PowerShell):**

```powershell
venv\Scripts\Activate.ps1
```

Once activated, your terminal prompt will show `(venv)` at the beginning.

---

### 3. Install project dependencies

With the virtual environment active, install all required packages:

```bash
pip install -r requirements.txt
```

---

### 4. Deactivate the virtual environment

When you are done working, deactivate the environment with:

```bash
deactivate
```

---

## Project Structure

```
SQL_Customer_RFM_Analysis/
├── venv/               # Virtual environment (not tracked by git)
├── requirements.txt    # Python dependencies
├── README.md           # Project documentation
└── ...                 # SQL scripts and analysis notebooks
```

---

## RFM Analysis Overview

RFM analysis segments customers based on three dimensions:

| Dimension   | Description                                      |
|-------------|--------------------------------------------------|
| **Recency** | How recently a customer made a purchase          |
| **Frequency** | How often a customer makes a purchase          |
| **Monetary** | How much money a customer spends               |

Each customer is scored on these dimensions to identify high-value customers, at-risk customers, and more.
