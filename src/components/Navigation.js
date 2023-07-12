import { ethers } from 'ethers';
import logo from '../assets/logo.svg';

const Navigation = ({ account, setAccount }) => {
  const connectHandler = async () => {
    const accounts = await window.ethereum.request({
      method: 'eth_requestAccounts',
    });
    const account = ethers.utils.getAddress(accounts[0]);
    setAccount(account);
  };

  return (
    <nav>
      <ul className="nav__links">
        <li>
          {/*  eslint-disable-next-line jsx-a11y/anchor-is-valid */}
          <a href="#">Buy</a>
        </li>
        <li>
          {/*  eslint-disable-next-line jsx-a11y/anchor-is-valid */}
          <a href="#">Rent</a>
        </li>
        <li>
          {/*  eslint-disable-next-line jsx-a11y/anchor-is-valid */}
          <a href="#">Sell</a>
        </li>
      </ul>

      <div className="nav__brand">
        <img src={logo} alt="Logo" />
        <h1>CryptoEstate</h1>
      </div>

      {account ? (
        <button type="button" className="nav__connect">
          {account.slice(0, 6) + '...' + account.slice(38, 42)}
        </button>
      ) : (
        <button type="button" className="nav__connect" onClick={connectHandler}>
          Connect
        </button>
      )}
    </nav>
  );
};

export default Navigation;
