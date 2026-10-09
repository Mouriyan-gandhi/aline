"""
Curated candidate company names for the target registry (plan: "Target company list").
These are real companies known to hire IT/software/AI roles in India, grouped by category.
This is NOT the final registry — it's the input to slug_prober.py, which tests each name
against the ATS platforms that support slug-guessing (Greenhouse, Lever, Ashby,
SmartRecruiters, Workable) and keeps only what actually resolves live. Honesty check: this
list is ~300-400 real names, not a fabricated path to "2000" — the prober's real yield is
reported as what it is, not inflated.
"""

GCC_CANDIDATES = [
    "Goldman Sachs", "JPMorgan Chase", "Morgan Stanley", "Barclays", "Deutsche Bank",
    "Bank of America", "Citi", "HSBC", "Standard Chartered", "UBS", "Wells Fargo",
    "BNY Mellon", "State Street", "Northern Trust", "American Express", "Visa", "Mastercard",
    "PayPal", "Walmart Global Tech", "Target", "Lowes", "Home Depot", "Best Buy", "Nike",
    "UnitedHealth Group", "Optum", "Cigna", "Boeing", "Honeywell", "GE", "Caterpillar",
    "John Deere", "Ford", "General Motors", "Delta Air Lines", "United Airlines", "FedEx",
    "UPS", "Verizon", "AT&T", "Comcast", "Disney", "Philips", "Siemens", "Bosch", "ABB",
    "Schneider Electric", "Shell", "BP", "ExxonMobil", "Maersk", "DHL", "Societe Generale",
    "BNP Paribas", "Credit Suisse", "ANZ", "Macquarie", "Commonwealth Bank", "Nomura",
    "Allstate", "Progressive", "MetLife", "Prudential", "AIG", "Swiss Re", "Munich Re",
    "Dell Technologies", "HP", "Hewlett Packard Enterprise", "Cisco", "Juniper Networks",
    "VMware", "NetApp", "Western Digital", "Micron", "Qualcomm", "Texas Instruments",
    "Analog Devices", "Intel", "AMD", "Broadcom", "Synopsys", "Cadence", "Arm",
    "Samsung Research", "LG", "Hyundai", "Mercedes-Benz", "BMW", "Volkswagen", "Continental",
    "ZF Group", "GE Healthcare", "Medtronic", "Abbott", "Pfizer", "Novartis", "Roche",
    "AstraZeneca", "Johnson and Johnson", "Merck", "Bristol Myers Squibb", "Wells Fargo India",
    "Thermo Fisher Scientific", "Danaher", "Illumina", "Agilent Technologies", "Becton Dickinson",
    "Stryker", "Zimmer Biomet", "Baxter", "3M", "Emerson Electric", "Rockwell Automation",
    "Eaton Corporation", "Parker Hannifin", "Illinois Tool Works", "Johnson Controls",
    "Carrier Global", "Trane Technologies", "Otis Worldwide", "Deere and Company",
    "Cummins", "Paccar", "Textron", "Raytheon", "Lockheed Martin", "Northrop Grumman",
    "L3Harris", "General Dynamics", "Airbus", "Rolls-Royce", "Safran", "Thales Group",
    "Nokia", "Ericsson", "ZTE", "Panasonic", "Sony", "Toshiba", "Hitachi", "Mitsubishi Electric",
    "Fujifilm", "Canon", "Epson", "Ricoh", "Xerox", "Kyndryl", "Infor", "Epicor",
    "Blackbaud", "Blackline", "Anaplan", "Celonis", "UKG", "Ceridian", "Paylocity",
    "Paycor", "ADP", "Paychex", "Cvent", "SurveyMonkey", "Medallia", "Verint",
    "NICE Ltd", "Genesys", "Avaya", "RingCentral", "8x8", "Five9", "Talkdesk",
    "Charles Schwab", "Fidelity Investments", "Vanguard", "BlackRock", "State Farm",
    "Liberty Mutual", "Travelers Insurance", "Chubb", "Marsh McLennan", "Aon", "Willis Towers Watson",
    "Moody's", "S&P Global", "MSCI", "FactSet", "Refinitiv", "LSEG", "ICE",
    "CME Group", "Nasdaq", "Intercontinental Exchange", "DTCC", "Northern Trust India",
    "Synchrony Financial", "Discover Financial", "Capital One", "Ally Financial",
    "Truist Financial", "PNC Financial", "US Bank", "Regions Financial", "M&T Bank",
    "KeyCorp", "Fifth Third Bank", "Huntington Bancshares", "Santander", "ING Group",
    "Rabobank", "ABN AMRO", "Commerzbank", "DZ Bank", "LBBW", "KfW", "EDF",
    "Engie", "TotalEnergies", "Eni", "Equinor", "Chevron", "ConocoPhillips",
    "Halliburton", "Schlumberger", "Baker Hughes", "National Grid", "E.ON",
    "RWE", "Iberdrola", "Enel", "Duke Energy", "NextEra Energy", "Southern Company",
]

INDIA_PRODUCT_UNICORN_CANDIDATES = [
    "Flipkart", "Myntra", "Swiggy", "Zomato", "Razorpay", "PhonePe", "CRED", "Paytm", "Zoho",
    "Freshworks", "Postman", "BrowserStack", "InMobi", "Meesho", "Zepto", "Dream11", "MPL",
    "Groww", "Upstox", "Zerodha", "Urban Company", "Nykaa", "PolicyBazaar", "Delhivery",
    "Porter", "Rapido", "BlackBuck", "Udaan", "Pine Labs", "Juspay", "Khatabook",
    "Vedantu", "Byjus", "Unacademy", "PhysicsWallah", "upGrad", "Simplilearn", "Licious",
    "BigBasket", "Blinkit", "Dunzo", "Ola", "Ola Electric", "Lenskart", "FirstCry",
    "Pepperfry", "CarDekho", "CarTrade", "Cars24", "Spinny", "Darwinbox", "Chargebee",
    "Whatfix", "Hasura", "Innovaccer", "Uniphore", "Yellow.ai", "Observe.AI", "Fractal",
    "CloudSEK", "Signzy", "HighRadius", "LeadSquared", "MoEngage", "CleverTap", "Druva",
    "Icertis", "Zenoti", "Capillary Technologies", "Netcore", "Exotel", "Kaleyra",
    "Wingify", "Gupshup", "Testbook", "Unstop", "Internshala", "Shiprocket", "ShareChat",
    "Moglix", "Infra.Market", "Apna", "Classplus", "Droom", "Toppr", "Doubtnut", "Embibe",
    "Scaler", "Masai School", "Crio.Do", "GeeksforGeeks", "InterviewBit", "Coding Ninjas",
    "HackerRank", "HackerEarth", "Adda247", "Oliveboard", "PrepLadder", "Great Learning",
    "Imarticus Learning", "Eruditus", "Hero Vired", "Smallcase", "INDmoney", "Fisdom",
    "Scripbox", "Kuvera", "ET Money", "Navi", "Stashfin", "KreditBee", "MoneyTap",
    "EarlySalary", "Innoviti", "BillDesk", "CCAvenue", "Zomato Hyperpure", "Swiggy Instamart",
    "Urban Ladder", "Housing.com", "NoBroker", "Square Yards", "99acres", "MagicBricks",
    "Naukri", "Info Edge", "Shaadi.com", "Practo", "1mg", "PharmEasy", "Netmeds", "Curefit",
    "HealthifyMe", "Pristyn Care", "DocOn", "Mfine", "Vymo", "Locus", "WebEngage",
    "Gupshup", "Pocket FM", "Kuku FM", "Josh Talks", "Sharechat Moj",
]

IT_SERVICES_CANDIDATES = [
    "TCS", "Infosys", "Wipro", "HCLTech", "Tech Mahindra", "Cognizant", "Capgemini",
    "LTIMindtree", "Persistent Systems", "Mphasis", "Hexaware", "Birlasoft", "Zensar",
    "Coforge", "Cyient", "Virtusa", "Sonata Software", "Happiest Minds",
    "Intellect Design Arena", "Newgen Software", "Ramco Systems", "KPIT Technologies",
    "Tata Elxsi", "eClerx", "WNS Global Services", "Genpact", "EXL Service", "Firstsource",
    "Concentrix", "Teleperformance", "Thoughtworks", "EPAM Systems", "Globant", "Endava",
    "Mindtree", "NIIT Technologies", "Larsen and Toubro Infotech", "Quest GlobAl",
    "Infogain", "Softtek", "GlobalLogic", "Nagarro", "Grid Dynamics", "DXC Technology",
    "Atos", "NTT Data", "Fujitsu", "Unisys", "CGI Group", "Publicis Sapient",
    "Slalom", "ThoughtSpot", "Synechron", "Yash Technologies", "Rolta", "3i Infotech",
    "Subex", "Majesco", "Diebold Nixdorf", "CitiusTech", "GEP Worldwide", "ANSR",
    "Accolite", "Xoriant", "Nitor Infotech", "Srijan Technologies", "InfoBeans",
    "Marlabs", "Incedo", "Indium Software", "Blend360", "Brillio", "Photon Interactive",
    "Oceaneering", "UST Global", "UST", "Movate", "[24]7.ai", "Transform",
]

GLOBAL_PRODUCT_CANDIDATES = [
    "Google", "Microsoft", "Amazon", "Meta", "Apple", "Adobe", "NVIDIA", "Salesforce",
    "Atlassian", "Uber", "ServiceNow", "Oracle", "SAP", "Cisco", "Intuit", "IBM", "Splunk",
    "Snowflake", "MongoDB", "Databricks", "Confluent", "HashiCorp", "Elastic", "Twilio",
    "Stripe", "Palo Alto Networks", "CrowdStrike", "Zscaler", "Okta", "Datadog", "New Relic",
    "PagerDuty", "GitLab", "GitHub", "Autodesk", "Qualtrics", "Zoom", "DocuSign", "Box",
    "Dropbox", "Pinterest", "LinkedIn", "Spotify", "Airbnb", "Booking.com", "Expedia",
    "eBay", "Two Sigma", "D.E. Shaw", "WorldQuant", "Micron Technology", "Seagate",
    "Arista Networks", "F5", "Pure Storage", "Rubrik", "Nutanix", "Veritas", "Commvault",
    "Informatica", "Teradata", "Cloudera", "Palantir Technologies", "C3 AI", "UiPath",
    "Automation Anywhere", "Blue Yonder", "Ansys", "PTC", "Trimble", "Workday",
    "Anthropic", "OpenAI", "Perplexity", "Scale AI", "Rippling", "Brex", "Plaid",
    "Asana", "Notion", "Figma", "Canva", "Miro", "Airtable", "Monday.com", "ClickUp", "Coda",
    "Loom", "Calendly", "Typeform", "Webflow", "Framer", "Linear", "Retool", "Vercel",
    "Netlify", "Supabase", "PlanetScale", "Render", "Replit", "Hugging Face",
    "Weights and Biases", "Together AI", "Mistral AI", "Cohere", "Modal Labs", "Runway",
    "ElevenLabs", "Glean", "Clay", "Attio", "Ramp", "Deel", "Remote", "Gusto", "Carta",
    "Mercury", "Chime", "Robinhood", "Coinbase", "Kraken", "Circle", "Chainalysis", "Affirm",
    "Klarna", "Revolut", "Wise", "Toast", "DoorDash", "Instacart", "Lyft", "Discord",
    "Reddit", "Snap", "Roblox", "Unity Technologies", "Epic Games", "Niantic", "Duolingo",
    "Coursera", "Udemy", "Chegg", "Grammarly", "Evernote", "Egnyte", "Smartsheet", "Wrike",
    "Opsgenie", "Honeycomb", "Sentry", "LaunchDarkly", "Split", "Optimizely", "Amplitude",
    "Mixpanel", "Segment", "Heap", "FullStory", "Hotjar", "Braze", "Iterable", "Customer.io",
    "Klaviyo", "SendGrid", "Front", "Intercom", "Zendesk", "Help Scout", "Drift", "Gong",
    "Outreach", "SalesLoft", "Clari", "6sense", "ZoomInfo", "Apollo.io", "Clearbit",
    "Figma", "Postman", "JFrog", "Sonar", "CircleCI", "Harness", "Buildkite", "Chronosphere",
    "Grafana Labs", "Dynatrace", "AppDynamics", "Wiz", "Snyk", "Checkmarx", "SentinelOne",
    "Tenable", "Qualys", "Rapid7", "Cloudflare", "Fastly", "Akamai", "Imperva", "Auth0",
]

FINTECH_BFSI_CANDIDATES = [
    "HDFC Bank", "ICICI Bank", "Axis Bank", "Kotak Mahindra Bank", "IndusInd Bank",
    "Yes Bank", "IDFC First Bank", "Bajaj Finserv", "Bajaj Finance", "SBI Card",
    "HDFC Life", "ICICI Lombard", "PayU", "Cashfree", "Instamojo", "BharatPe", "MobiKwik",
    "Simpl", "Slice", "Jupiter Money", "Fi Money", "Niyo", "Open Financial", "Angel One",
    "5paisa", "IIFL", "Motilal Oswal", "Edelweiss", "Zeta",
    "Tide", "Starling Bank", "Monzo", "N26", "Nubank", "Brex", "Ramp", "Marqeta",
    "Adyen", "Checkout.com", "Worldpay", "Square", "Block", "Bill.com", "Melio",
    "Tipalti", "Modern Treasury", "Unit", "Synctera", "Alloy", "Persona", "Sardine",
    "Sift", "Forter", "Riskified", "Signifyd", "ComplyAdvantage", "Trulioo", "Onfido",
    "Jumio", "Plaid India", "Setu", "Decentro", "M2P Fintech", "Yap", "Finbox",
    "CredAvenue", "Lendingkart", "Capital Float", "FlexiLoans", "KreditBee India",
    "Perfios", "Karza Technologies", "SBI General Insurance", "Acko", "Digit Insurance",
    "Policybazaar", "Turtlemint", "InsuranceDekho", "RenewBuy",
]

# Round 2 additions (2026-10-08), per explicit direction to target "all companies 3rd/4th
# year + early professionals would target in India." Focused on: more India product/startup
# names (the category least covered so far, best suited to automated Greenhouse/Lever/Ashby
# discovery rather than Workday), more global mid-size SaaS (same reasoning), plus more names
# in the GCC sub-categories (pharma/medtech, US financial, hardware/semiconductor) that showed
# the strongest Workday hit rate in manual testing.
INDIA_PRODUCT_ROUND2 = [
    "OkCredit", "LEAD School", "Cuemath", "WhiteHat Jr", "Jumbotail", "ElasticRun", "Zetwerk",
    "OfBusiness", "Captain Fresh", "DeHaat", "Ninjacart", "WayCool", "Purplle",
    "Honasa Consumer", "boAt", "Noise", "Wakefit", "CaratLane", "Bluestone", "Livspace",
    "HomeLane", "Rentomojo", "Furlenco", "Zypp Electric", "Yulu", "Bounce", "Shadowfax",
    "Xpressbees", "ClickPost", "Pickrr", "Ecom Express", "Rivigo", "FarEye", "LogiNext",
    "WareIQ", "Increff", "Unicommerce", "LambdaTest", "Appsmith", "Draup", "Keka HR",
    "Zimyo", "HROne", "GreytHR", "Gaana", "JioSaavn", "Disney Hotstar", "MX Player",
    "Chingari", "Dailyhunt", "Inshorts", "Koo", "Trell", "Craftsvilla", "Limeroad",
    "Stage OTT", "Mswipe", "Ezetap", "CredR", "Olx India", "Quikr", "Zoomcar", "Revv",
    "Sarvam AI", "Krutrim", "Mu Sigma", "Tiger Analytics", "LatentView Analytics",
    "Course5 Intelligence", "Games24x7", "Nazara Technologies", "WinZO", "Zupee", "Loco",
    "Newton School", "Pesto Tech", "Portea", "Medlife", "DocsApp", "Lybrate", "Curofy",
    "Emeritus", "NoBroker", "Square Yards India", "Housing India",
]

GLOBAL_SAAS_ROUND2 = [
    "Pendo", "Appcues", "LogRocket", "Lightstep", "Rootly", "incident.io", "Statuspage",
    "Better Stack", "Checkly", "Insomnia", "Hoppscotch", "SmartBear", "Budibase", "n8n",
    "Zapier", "Make Integromat", "Workato", "Tray.io", "MuleSoft", "Boomi", "mParticle",
    "Rudderstack", "Census", "Hightouch", "Fivetran", "Airbyte", "dbt Labs", "Dagster",
    "Prefect", "Astronomer", "Redpanda", "Materialize", "ClickHouse", "SingleStore",
    "CockroachDB", "Yugabyte", "Neon", "Prisma", "Apollo GraphQL", "Railway App", "Fly.io",
    "DigitalOcean", "Vultr", "Rapyd", "Nium", "Airwallex", "Remitly", "Payoneer", "Novo",
    "Bluevine",
]

GCC_ROUND2 = [
    # Pharma/medtech — 4/4 hit rate observed (Pfizer, Novartis, AstraZeneca, Medtronic)
    "Merck and Co", "Bristol Myers Squibb", "GSK", "Roche", "Sanofi", "Biogen", "Regeneron",
    "Gilead Sciences", "Vertex Pharmaceuticals", "Boston Scientific", "Eli Lilly",
    "Amgen", "Takeda",
    # US financial/insurance GCCs — ~67% hit rate observed
    "Northern Trust", "State Street", "Allstate", "Travelers Insurance", "Synchrony",
    "Discover Financial Services", "Ally Financial", "Truist Financial", "US Bancorp",
    "Voya Financial", "Principal Financial Group", "Lincoln Financial", "Unum Group",
    "Globe Life", "Aflac", "Hartford Financial",
    # Hardware/semiconductor — ~62% hit rate observed
    "Marvell Technology", "ON Semiconductor", "Skyworks Solutions", "Lattice Semiconductor",
    "KLA Corporation", "Applied Materials", "Lam Research", "Teradyne", "NXP Semiconductors",
    "Infineon Technologies", "STMicroelectronics", "Renesas Electronics", "Entegris",
]

# Round 3 additions (2026-10-09), per direction to keep pushing registered-company count.
# Targets categories/sub-segments underrepresented in Round 1/2: consumer packaged goods /
# FMCG GCCs (none were in the original list at all), consulting/professional-services firms
# with real India analyst/engineer hiring (also entirely absent before — IT_SERVICES had zero
# Big 4/strategy-consulting names), more semiconductor design houses with dedicated India
# engineering centers, a newer wave of India AI-native startups, and US financial-services GCC
# names not yet tried. Checked each name here against the existing five lists above before
# adding — not guaranteed zero overlap (slug_prober re-testing an existing hit is harmless,
# just a wasted request), but a real pass was made, not a blind dump.
CONSULTING_PROFESSIONAL_SERVICES = [
    "Deloitte", "KPMG", "EY", "PwC", "Accenture", "McKinsey and Company",
    "Boston Consulting Group", "Bain and Company", "Kearney", "Oliver Wyman",
    "Roland Berger", "Strategy and PwC", "Protiviti", "Alvarez and Marsal",
    "FTI Consulting", "Grant Thornton", "BDO", "RSM International", "Crowe Global",
    "Baker Tilly", "Zinnov", "RedSeer", "Praxis Global Alliance", "ZS Associates",
    "Simon Kucher", "L.E.K. Consulting", "Charles River Associates", "NERA Economic Consulting",
    "Cornerstone Research", "Analysis Group", "Huron Consulting", "Guidehouse",
    "West Monroe", "Slalom Consulting", "Booz Allen Hamilton", "ICF International",
]

CPG_FMCG_GCC = [
    "Procter and Gamble", "Unilever", "Nestle", "PepsiCo", "Coca-Cola", "Mondelez International",
    "Kraft Heinz", "General Mills", "Kellanova", "Hershey", "Mars Incorporated", "Diageo",
    "Pernod Ricard", "AB InBev", "Heineken", "Colgate-Palmolive", "Kimberly-Clark",
    "Reckitt Benckiser", "Haleon", "Kenvue", "L'Oreal", "Estee Lauder", "LVMH", "Richemont",
    "Levi Strauss", "Gap Inc", "VF Corporation", "Under Armour", "lululemon", "Adidas",
    "Puma", "New Balance", "PVH Corp", "Ralph Lauren",
]

US_FINANCIAL_GCC_ROUND3 = [
    "Jefferies", "Raymond James", "Stifel Financial", "Piper Sandler", "Evercore", "Lazard",
    "Houlihan Lokey", "PJT Partners", "Moelis and Company", "Guggenheim Partners", "Oppenheimer",
    "William Blair", "Robert W Baird", "RBC Capital Markets", "TD Securities", "BMO Financial Group",
    "CIBC", "Scotiabank", "National Australia Bank", "Westpac",
]

SEMICONDUCTOR_DESIGN_HOUSES = [
    "GlobalFoundries", "UMC", "TSMC", "SK Hynix", "Samsung Electronics", "Credo Technology",
    "Astera Labs", "Ambarella", "Silicon Labs", "MaxLinear", "Diodes Incorporated",
    "Monolithic Power Systems", "Power Integrations", "Allegro MicroSystems", "Wolfspeed",
    "Cirrus Logic", "Synaptics", "Rambus", "CEVA Inc", "Infinera", "Ciena", "Amphenol",
    "TE Connectivity", "Molex", "eInfochips", "Sasken Technologies", "L&T Semiconductor Technologies",
    "Mindteck", "VVDN Technologies", "Mirafra Technologies",
]

INDIA_AI_NATIVE_ROUND3 = [
    "Lyzr AI", "Rezo.ai", "Haptik", "Slang Labs", "Vernacular.ai", "Verloop.io", "Cogcent",
    "Flexiple", "Turing", "Multiplier", "Fyle", "Dukaan", "Jiffy.ai", "Floworks",
    "Orbo.ai", "Wisdom AI", "Avaamo", "Yellow Messenger", "Skit.ai", "Convin",
]

PHARMA_MEDTECH_ROUND3 = [
    "Novo Nordisk", "Teva Pharmaceutical", "Viatris", "Organon", "Alkermes",
    "Jazz Pharmaceuticals", "Incyte", "Alexion Pharmaceuticals", "Horizon Therapeutics",
    "Dexcom", "Insulet", "Edwards Lifesciences", "Intuitive Surgical", "Hologic", "ResMed",
    "Cochlear", "Align Technology", "IDEXX Laboratories", "Catalent", "Lonza", "WuXi AppTec",
]

ALL_CATEGORIES = {
    "gcc": GCC_CANDIDATES + GCC_ROUND2 + CPG_FMCG_GCC + US_FINANCIAL_GCC_ROUND3 + PHARMA_MEDTECH_ROUND3,
    "india_product_unicorn": INDIA_PRODUCT_UNICORN_CANDIDATES + INDIA_PRODUCT_ROUND2 + INDIA_AI_NATIVE_ROUND3,
    "it_services": IT_SERVICES_CANDIDATES + CONSULTING_PROFESSIONAL_SERVICES,
    "global_product": GLOBAL_PRODUCT_CANDIDATES + GLOBAL_SAAS_ROUND2 + SEMICONDUCTOR_DESIGN_HOUSES,
    "fintech_bfsi": FINTECH_BFSI_CANDIDATES,
}
