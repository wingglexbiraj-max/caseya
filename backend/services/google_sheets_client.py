import os
import logging
from typing import List, Dict, Any

logger = logging.getLogger("caseya.sheets")

class GoogleSheetsClient:
    """
    Secure Google Sheets adapter for CASEYA.
    Credentials and service account keys are stored ONLY on the backend server,
    never exposed to the frontend browser or Vercel client bundle.
    """
    def __init__(self):
        self.spreadsheet_id = os.getenv("GOOGLE_SHEETS_SPREADSHEET_ID")
        self.service_account_path = os.getenv("GOOGLE_SERVICE_ACCOUNT_FILE", "credentials/service_account.json")
        self.client = None
        self._init_client()

    def _init_client(self):
        if os.path.exists(self.service_account_path) and self.spreadsheet_id:
            try:
                import gspread
                self.client = gspread.service_account(filename=self.service_account_path)
                logger.info("Connected to Google Sheets backend store successfully.")
            except Exception as e:
                logger.warning(f"Could not connect to Google Sheets: {e}. Falling back to internal store.")
        else:
            logger.info("Google service account not found or SPREADSHEET_ID not set. Operating in local memory/file mode.")

    def append_row(self, sheet_name: str, row_data: List[Any]) -> bool:
        if not self.client or not self.spreadsheet_id:
            return False
        try:
            sh = self.client.open_by_key(self.spreadsheet_id)
            worksheet = sh.worksheet(sheet_name)
            worksheet.append_row(row_data)
            return True
        except Exception as e:
            logger.error(f"Error appending row to Google Sheets '{sheet_name}': {e}")
            return False

    def get_all_records(self, sheet_name: str) -> List[Dict[str, Any]]:
        if not self.client or not self.spreadsheet_id:
            return []
        try:
            sh = self.client.open_by_key(self.spreadsheet_id)
            worksheet = sh.worksheet(sheet_name)
            return worksheet.get_all_records()
        except Exception as e:
            logger.error(f"Error reading records from Google Sheets '{sheet_name}': {e}")
            return []
